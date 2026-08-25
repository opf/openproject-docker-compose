# frozen_string_literal: true

#-- copyright
# Live Solutions customization for OpenProject.
#
# This migration creates the per-user hierarchy collapse state table used by
# issue #777. It stores the user's last hierarchy bulk action (all collapsed
# or all expanded) and the set of individually collapsed work package ids so
# the state is persisted in the backend, applies across browsers/devices, and
# is automatically present for all existing and future users.
#--

class CreateUserHierarchyCollapseStates < ActiveRecord::Migration[7.1]
  def up
    create_table :user_hierarchy_collapse_states do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :collapsed_ids, null: false, default: []
      t.boolean :all_collapsed, null: false, default: true
      t.timestamps
    end

    # Seed every existing user with the default "all collapsed" state.
    # Users created after this migration are handled by the User model patch.
    execute <<~SQL.squish
      INSERT INTO user_hierarchy_collapse_states (user_id, collapsed_ids, all_collapsed, created_at, updated_at)
      SELECT id, '[]'::jsonb, true, NOW(), NOW()
      FROM users
      WHERE type = 'User'
      ON CONFLICT (user_id) DO NOTHING
    SQL
  end

  def down
    drop_table :user_hierarchy_collapse_states
  end
end
