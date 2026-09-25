# frozen_string_literal: true

#-- copyright
# Live Solutions customization for OpenProject.
#
# Ensures the per-page preference defaults to 100 and the global hierarchy
# collapse preference defaults to true for every user. This applies to new
# preferences as well as existing ones when the settings are missing.
#
# Important: we do not mutate the serialized hash returned by ActiveRecord;
# we return a duplicate with the defaults applied, so the record is only
# marked dirty when the caller actually changes something.
#--

module OpenProject::Livesolutions::Patches
  module UserPreferencePatch
    def settings
      value = super
      value = {} if value.blank?

      with_defaults = value.dup
      with_defaults[:per_page] = 100 if with_defaults[:per_page].blank?
      with_defaults[:hierarchy_collapsed_all] = true if with_defaults[:hierarchy_collapsed_all].nil?
      with_defaults
    end

    def settings=(value)
      value = {} if value.blank?
      value[:per_page] = 100 if value[:per_page].blank?
      value[:hierarchy_collapsed_all] = true if value[:hierarchy_collapsed_all].nil?
      super(value)
    end
  end
end
