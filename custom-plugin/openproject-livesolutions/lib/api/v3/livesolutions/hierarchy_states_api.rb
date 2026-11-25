# frozen_string_literal: true

#-- copyright
# Live Solutions customization for OpenProject.
#
# API endpoints used by the frontend hierarchy collapse-all/expand-all patch
# to read and write the per-user backend state. Mounted into API::V3::Root by
# the engine patch.
#--

module API
  module V3
    module Livesolutions
      class HierarchyStatesAPI < ::API::OpenProjectAPI
        resource :livesolutions_hierarchy_state do
          after_validation do
            authorize_by_with_raise(current_user.logged?)
          end

          helpers do
            def hierarchy_state
              @hierarchy_state ||= UserHierarchyCollapseState.find_or_initialize_by(user: current_user)
            end

            def normalize_collapsed_ids(ids)
              Array(ids).map { |id| id.to_i }.select { |id| id > 0 }.uniq
            end
          end

          get do
            state = hierarchy_state
            {
              all_collapsed: state.all_collapsed,
              collapsed_ids: state.collapsed_ids
            }
          end

          params do
            requires :all_collapsed, type: Boolean
            optional :collapsed_ids, type: Array[Integer]
          end
          post do
            state = hierarchy_state
            state.all_collapsed = declared_params[:all_collapsed]
            state.collapsed_ids = normalize_collapsed_ids(declared_params[:collapsed_ids])
            if state.save
              {
                all_collapsed: state.all_collapsed,
                collapsed_ids: state.collapsed_ids
              }
            else
              raise ::API::Errors::InvalidRequestBody.new(state.errors.full_messages.join(", "))
            end
          end
        end
      end
    end
  end
end
