# frozen_string_literal: true

module Heroku
  #
  # Handles responses when errors arise to set correct messages and response statuses.
  #
  class ErrorsController < Heroku::ApiController
    #
    # Default response for 404 Not Found error, unexistent routes or invalid format requests.
    #
    def not_found
      resp = {
        id: "not_found",
        message: I18n.t("heroku.error_messages.not_found")
      }

      render json: resp.to_json, status: :not_found, content_type: Heroku::MimeType::ADDON_PARTNER_API
    end
  end
end
