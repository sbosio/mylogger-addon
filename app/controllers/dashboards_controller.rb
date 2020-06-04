# frozen_string_literal: true

#
# Resource dashboard.
#
class DashboardsController < ApplicationController
  #
  # GET /
  #
  def show
    @resource = Resource.with_state(:provisioned).find(session[:resource_id])
    @plan = Heroku::Plan::CONFIGURED_PLANS[@resource.plan]
  end
end
