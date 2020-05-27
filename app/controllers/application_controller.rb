# frozen_string_literal: true

#
# Base controller class.
#
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :forbidden

  protected

  #
  # Drop any pending session to a resource that was just deprovisioned (just in case) and render the customized 403 Forbidden page.
  #
  def forbidden
    session[:resource_id] = nil
    render template: "shared/forbidden", layout: false, status: :forbidden
  end
end
