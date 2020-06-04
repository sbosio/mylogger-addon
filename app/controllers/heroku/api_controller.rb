# frozen_string_literal: true

module Heroku
  #
  # Base controller class for API requests.
  #
  class ApiController < ActionController::API
    rescue_from StandardError, with: :internal_server_error
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from Heroku::NotAuthorizedError, with: :unauthorized
    rescue_from Heroku::UnavailablePlanError, with: :unprocessable_entity

    private

    #
    # Default response for 500 Internal Server Error
    #
    def internal_server_error(exception)
      resp = {
        id: "internal_server_error",
        message: I18n.t("heroku.error_messages.internal_server_error", exception_message: exception.message.tr("\n", ' \ '))
      }

      render json: resp.to_json, status: :internal_server_error, content_type: Heroku::MimeType::ADDON_PARTNER_API
    end

    #
    # Default response for 401 Unauthorized
    #
    def unauthorized
      resp = {
        id: "unauthorized",
        message: I18n.t("heroku.error_messages.unauthorized")
      }

      render json: resp.to_json, status: :unauthorized, content_type: Heroku::MimeType::ADDON_PARTNER_API
    end

    #
    # Default response for 422 Unprocessable Entity
    #
    def unprocessable_entity(exception)
      resp = {
        id: "unprocessable_entity",
        message: exception.message
      }

      render json: resp.to_json, status: :unprocessable_entity, content_type: Heroku::MimeType::ADDON_PARTNER_API
    end
  end
end
