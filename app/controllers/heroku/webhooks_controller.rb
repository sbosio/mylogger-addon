# frozen_string_literal: true

module Heroku
  #
  # Controller that handles log frames sent through the Heroku log drain.
  #
  class WebhooksController < ActionController::Metal
    #
    # POST /webhooks
    #
    def create
      Rails.logger.info do
        {webhook_event_payload: request.raw_post}
      end
      [204, {}, ""]
    end
  end
end
