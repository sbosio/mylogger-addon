# frozen_string_literal: true

module Logplex
  #
  # Handles responses when errors arise to set correct messages and response statuses.
  #
  class ErrorsController < Logplex::ApiController
    #
    # Default response for 404 Not Found error, unexistent routes or invalid format requests.
    #
    def not_found
      head :not_found
    end

    #
    # Default response for 415 Unsupported Media Type error.
    #
    def unsupported_media_type
      head :unsupported_media_type
    end
  end
end
