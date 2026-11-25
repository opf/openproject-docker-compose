# frozen_string_literal: true

#-- copyright
# Live Solutions customization for OpenProject.
#
# Makes lag respect a successor work package's ignore_non_working_days flag.
# When a successor is set to ignore non-working days (i.e. "Working days only"
# is unchecked), lag is interpreted as calendar days instead of working days.
#--

module OpenProject::Livesolutions::Patches
  module AllDaysLagPatch
    def lag(predecessor_date, successor_date)
      return nil unless predecessor_date && successor_date

      (successor_date - predecessor_date - 1).to_i
    end

    def with_lag(date, lag)
      return nil unless date

      date + (lag || 0).days + 1.day
    end
  end
end
