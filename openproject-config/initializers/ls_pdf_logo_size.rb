# frozen_string_literal: true

# Live Solutions: enlarge the default PDF export logo rendering so the full
# LS wordmark remains readable on covers and page headers.

Rails.application.config.to_prepare do
  # Project / work package PDF exports
  Exports::PDF::Components::CoverStyles.module_eval do
    def cover_header_logo_height
      resolve_pt(@styles.dig(:cover, :header, :logo_height), 60)
    end
  end

  Exports::PDF::Components::PageStyles.module_eval do
    def page_logo_height
      resolve_pt(@styles.dig(:page_logo, :height), 35)
    end
  end
end
