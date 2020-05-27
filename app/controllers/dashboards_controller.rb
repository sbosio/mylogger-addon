# frozen_string_literal: true

#
# Resource dashboard.
#
class DashboardsController < ApplicationController
  # before_action :authenticate_sso_login!

  #
  # GET /
  #
  def show
    render :show, layout: false
  end
end
