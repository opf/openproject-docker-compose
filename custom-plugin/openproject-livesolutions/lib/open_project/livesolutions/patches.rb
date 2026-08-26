# frozen_string_literal: true

#-- copyright
# Live Solutions customization for OpenProject.
#
# Require all monkey-patches used by this plugin.
#--

require 'open_project/livesolutions/patches/all_days_lag_patch'
require 'open_project/livesolutions/patches/current_user_cloudflare_patch'
require 'open_project/livesolutions/patches/query_params_representer_patch'
require 'open_project/livesolutions/patches/relation_lag_patch'
require 'open_project/livesolutions/patches/user_preference_patch'
require 'open_project/livesolutions/patches/user_patch'
