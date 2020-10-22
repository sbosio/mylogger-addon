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
      head :no_content
    end
  end
end
