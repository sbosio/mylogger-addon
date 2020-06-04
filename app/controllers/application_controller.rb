# frozen_string_literal: true

#
# Base controller class.
#
class ApplicationController < ActionController::Base
  before_action :authenticate_sso_login!
  rescue_from ActiveRecord::RecordNotFound, with: :forbidden

  #
  # Drop any pending session to a resource that was just deprovisioned (just in case) and render the customized 403 Forbidden page.
  #
  def forbidden
    session[:resource_id] = nil
    render template: "shared/forbidden", layout: false, status: :forbidden
  end

  private

  def authenticate_sso_login!
    forbidden unless session[:resource_id].present?
  end
end
