# frozen_string_literal: true

# CSS and JS are injected via mounted view overrides and docker-compose volume
# mount; the legacy hook listener is removed to avoid an OpenProject::Hook
# load-order dependency that breaks plugin boot in OpenProject 17.

module OpenProject::Livesolutions
  class Engine < ::Rails::Engine
    engine_name :openproject_livesolutions

    initializer 'openproject_livesolutions.assets' do |app|
      app.config.assets.paths << root.join('app', 'assets', 'stylesheets').to_s
      app.config.assets.paths << root.join('app', 'assets', 'javascripts').to_s
      app.config.assets.precompile += %w[livesolutions/theme.css]
    end

    initializer 'openproject_livesolutions.append_migrations' do |app|
      # Register the plugin's db/migrate directory with the main application
      # so `rails db:migrate` picks up our custom migrations.
      app.config.paths['db/migrate'] << root.join('db', 'migrate').to_s
    end

    config.to_prepare do
      require 'open_project/livesolutions/patches'

      unless Accounts::CurrentUser.ancestors.include?(OpenProject::Livesolutions::Patches::CurrentUserCloudflarePatch)
        Accounts::CurrentUser.prepend OpenProject::Livesolutions::Patches::CurrentUserCloudflarePatch
      end

      unless WorkPackages::Shared::AllDays.ancestors.include?(OpenProject::Livesolutions::Patches::AllDaysLagPatch)
        WorkPackages::Shared::AllDays.prepend OpenProject::Livesolutions::Patches::AllDaysLagPatch
      end

      unless Relation.ancestors.include?(OpenProject::Livesolutions::Patches::RelationLagPatch)
        Relation.prepend OpenProject::Livesolutions::Patches::RelationLagPatch
      end

      unless API::Decorators::QueryParamsRepresenter.ancestors.include?(OpenProject::Livesolutions::Patches::QueryParamsRepresenterPatch)
        API::Decorators::QueryParamsRepresenter.prepend OpenProject::Livesolutions::Patches::QueryParamsRepresenterPatch
      end

      unless UserPreference.ancestors.include?(OpenProject::Livesolutions::Patches::UserPreferencePatch)
        UserPreference.prepend OpenProject::Livesolutions::Patches::UserPreferencePatch
      end

      unless User.ancestors.include?(OpenProject::Livesolutions::Patches::UserPatch)
        User.include OpenProject::Livesolutions::Patches::UserPatch
      end
    end

    config.after_initialize do
      # Mount the Livesolutions API endpoints into API::V3::Root once the core
      # API classes are loaded and before the route set is frozen. We force-load
      # the API class here because the plugin lib/ path is not in Rails'
      # autoload paths by default.
      begin
        require 'api/v3/livesolutions/hierarchy_states_api'
      rescue LoadError => e
        Rails.logger.error "[LiveSolutions] unable to load HierarchyStatesAPI: #{e.message}"
      end

      if defined?(::API::V3::Root) && defined?(::API::V3::Livesolutions::HierarchyStatesAPI) &&
         !::API::V3::Root.instance_variable_defined?(:@livesolutions_api_mounted)
        ::API::V3::Root.class_eval do
          mount ::API::V3::Livesolutions::HierarchyStatesAPI
        end
        ::API::V3::Root.instance_variable_set(:@livesolutions_api_mounted, true)
      end
    end
  end
end
