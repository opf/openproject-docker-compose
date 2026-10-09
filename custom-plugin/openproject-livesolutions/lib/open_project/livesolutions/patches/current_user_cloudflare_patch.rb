# frozen_string_literal: true

module OpenProject::Livesolutions::Patches
  module CurrentUserCloudflarePatch
    def find_current_user
      user = current_cloudflare_user
      return user if user&.logged? && user&.active?

      super
    end

    private

    def current_cloudflare_user
      return nil unless cloudflare_access_enabled?

      email = request.headers['Cf-Access-Authenticated-User-Email'].presence
      return nil if email.blank?

      email = email.downcase.strip

      user = User.active.find_by(mail: email) || create_cloudflare_user(email)
      return nil unless user&.active?

      # Establish a session for this user.
      login_user(user)
      user
    rescue StandardError => e
      Rails.logger.error "[CloudflareAccessAuth] authentication failed for #{email}: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      nil
    end

    def create_cloudflare_user(email)
      name = request.headers['Cf-Access-Authenticated-User-Name'].presence || email.split('@').first
      firstname, lastname = split_name(name)
      login = unique_login_from_email(email)
      password = SecureRandom.hex(32)

      user = User.new(
        mail: email,
        login: login,
        firstname: firstname,
        lastname: lastname,
        status: User.statuses[:active],
        admin: false,
        password: password,
        password_confirmation: password
      )

      # SSO users do not need local password validation.
      user.save(validate: false)
      user
    end

    def split_name(name)
      parts = name.to_s.strip.split
      if parts.length > 1
        [parts.first, parts[1..-1].join(' ')]
      else
        [parts.first || 'Live', 'Solutions']
      end
    end

    def unique_login_from_email(email)
      local = email.split('@').first.to_s.downcase
      local = local.gsub(/[^a-z0-9_\-.]/, '_')[0, 60]
      return email.gsub(/[^a-z0-9_\-.@]/, '_')[0, 60] if local.blank?

      base = local
      counter = 0
      while User.exists?(login: base)
        counter += 1
        suffix = "_#{counter}"
        base = "#{local[0, 60 - suffix.length]}#{suffix}"
      end
      base
    end

    def cloudflare_access_enabled?
      ENV.fetch('TRUST_CF_ACCESS_EMAIL', 'false').to_s == 'true'
    end
  end
end
