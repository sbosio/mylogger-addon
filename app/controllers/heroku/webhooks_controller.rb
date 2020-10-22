# frozen_string_literal: true

module Heroku
  #
  # Controller that handles log frames sent through the Heroku log drain.
  #
  class WebhooksController < Heroku::ApiController
    #
    # POST /webhooks
    #
    def create
      Rails.logger.info ActiveSupport::JSON.decode(req.body)

      head :no_content
    end
  end
end
