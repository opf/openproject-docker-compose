# frozen_string_literal: true

#-- copyright
# Live Solutions customization for OpenProject.
#
# Uses the successor work package's day computation mode when calculating the
# earliest start date imposed by a follows relation. When the successor ignores
# non-working days, lag is interpreted in calendar days; otherwise it is
# interpreted in working days.
#--

module OpenProject::Livesolutions::Patches
  module RelationLagPatch
    def successor_soonest_start
      if follows? && predecessor_date
        days = WorkPackages::Shared::Days.for(successor)
        days.with_lag(predecessor_date, lag)
      end
    end
  end
end
