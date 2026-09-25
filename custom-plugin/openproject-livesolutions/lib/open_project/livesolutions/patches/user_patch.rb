# frozen_string_literal: true

#-- copyright
# Live Solutions customization for OpenProject.
#
# Ensures every user (existing and future) has a UserHierarchyCollapseState
# row with the default "all collapsed" state. New users get the row created
# automatically on user creation via after_create.
#--

module OpenProject::Livesolutions::Patches
  module UserPatch
    extend ActiveSupport::Concern

    included do
      has_one :user_hierarchy_collapse_state, dependent: :destroy
      after_create :livesolutions_ensure_hierarchy_collapse_state
    end

    private

    def livesolutions_ensure_hierarchy_collapse_state
      UserHierarchyCollapseState.find_or_create_by(user: self) do |state|
        state.all_collapsed = true
        state.collapsed_ids = []
      end
    end
  end
end
