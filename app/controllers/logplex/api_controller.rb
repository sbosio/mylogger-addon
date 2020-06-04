# frozen_string_literal: true

module Logplex
  #
  # Base controller class for API requests.
  #
  class ApiController < ActionController::API
    rescue_from StandardError, with: :internal_server_error
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

    private

    #
    # Default response for 500 Internal Server Error
    #
    def internal_server_error
      head :internal_server_error
    end

    #
    # Default response for 404 Not Found
    #
    def not_found
      head :not_found
    end

    #
    # Default response for 422 Unprocessable Entity
    #
    def unprocessable_entity
      head :unprocessable_entity
    end
  end
end
