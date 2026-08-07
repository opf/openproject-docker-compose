# CSS is injected via mounted view overrides and docker-compose volume mount;
# the legacy hook listener is removed to avoid an OpenProject::Hook load-order
# dependency that breaks plugin boot in OpenProject 17.

module OpenProject::Livesolutions
  class Engine < ::Rails::Engine
    engine_name :openproject_livesolutions

    initializer 'openproject_livesolutions.assets' do |app|
      app.config.assets.paths << root.join('app', 'assets', 'stylesheets').to_s
      app.config.assets.paths << root.join('app', 'assets', 'javascripts').to_s
      app.config.assets.precompile += %w[livesolutions/theme.css]
    end

    config.to_prepare do
      require 'open_project/livesolutions/patches'
      Accounts::CurrentUser.prepend OpenProject::Livesolutions::Patches::CurrentUserCloudflarePatch
    end
  end
end
