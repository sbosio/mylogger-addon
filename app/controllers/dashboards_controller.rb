# frozen_string_literal: true

#
# Resource dashboard.
#
class DashboardsController < ApplicationController
  skip_before_action :authenticate_sso_login!, if: -> { Rails.env.development? }

  #
  # GET /
  #
  def show
    @resource = if Rails.env.development?
      Resource.with_state(:provisioned).last
    else
      Resource.with_state(:provisioned).find(session[:resource_id])
    end
    @plan = Heroku::Plan::CONFIGURED_PLANS[@resource.plan]
  end
end
