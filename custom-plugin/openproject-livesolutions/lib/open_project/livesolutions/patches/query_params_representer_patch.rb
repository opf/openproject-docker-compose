# frozen_string_literal: true

#-- copyright
# Live Solutions customization for OpenProject.
#
# Forces the default work-package collection page size to 100 for every user
# and every query (#778). The default was 20 because
# Setting.per_page_options_array.first == 20. This patch changes the API
# default hash so fresh requests, exported views, and embedded queries all
# use 100 unless the user explicitly overrides it.
#--

module OpenProject::Livesolutions::Patches
  module QueryParamsRepresenterPatch
    def default_hash
      super.merge(pageSize: 100)
    end
  end
end
