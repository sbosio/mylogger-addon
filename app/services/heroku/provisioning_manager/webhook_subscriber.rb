# frozen_string_literal: true

module Heroku
  module ProvisioningManager
    #
    # Subscribes to receive different webhooks events.
    #
    class WebhookSubscriber < ApplicationService
      SUBSCRIBE_PAYLOAD = {
        authorization: "Bearer #{Rails.application.credentials.webhook_events_authorization}",
        include: [
          "api:addon",
          "api:addon-attachment",
          "api:app"
        ],
        level: "sync",
        url: "https://mylogger-addon.herokuapp.com/heroku/webhooks"
      }.freeze

      def initialize(resource)
        @resource = resource
      end

      #
      # Subscribes to receive different webhook events
      #
      # - api:addon
      # - api:addon_attachment
      # - api:app
      #
      # @return [true, false] to notify the caller if the method executed successfully or not.
      #
      def call
        heroku = PlatformAPI.connect_oauth(@resource.fresh_access_token)
        heroku.addon_webhook.create @resource.external_id, SUBSCRIBE_PAYLOAD
        true
      rescue => e
        Rails.logger.error { "Heroku::ProvisioningManager::WebhookSubscriber unexpected error: #{e.message}" }
        false
      end
    end
  end
end
