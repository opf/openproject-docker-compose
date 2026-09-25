# frozen_string_literal: true

#-- copyright
# Live Solutions customization for OpenProject.
#
# Backend persistence for the hierarchy collapse/expand all feature (#777).
# One row per user holds the global hierarchy state. The row is created
# automatically for every user with sensible defaults (all collapsed) and is
# updated by the frontend whenever the user clicks collapse/expand all or
# toggles individual hierarchy rows.
#--

class UserHierarchyCollapseState < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true, uniqueness: true
  validates :all_collapsed, inclusion: { in: [true, false] }

  # Ensure we never store nil; default to an empty array.
  def collapsed_ids
    super || []
  end
end
