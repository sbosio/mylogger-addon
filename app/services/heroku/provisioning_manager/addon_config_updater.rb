# frozen_string_literal: true

module Heroku
  module ProvisioningManager
    #
    # Updates the configuration and provisioning status for this add-on on the linked Heroku application.
    #
    class AddonConfigUpdater < ApplicationService
      def initialize(resource)
        @resource = resource
      end

      #
      # Notifies Heroku that the resource is ready to be used.
      #
      # On a real add-on you probably would need to set some config vars on the Heroku App, but as this demo add-on doesn't
      # requires any, we're not setting them and we only mark the add-on as provisioned.
      #
      # @return [true, false] to notify the caller if the method executed successfully or not.
      #
      def call
        heroku = PlatformAPI.connect_oauth(@resource.fresh_access_token)
        heroku.addon_action.provision @resource.external_id
        true
      rescue StandardError => e
        Rails.logger.error { "Heroku::ProvisioningManager::AddonConfigUpdater unexpected error: #{e.message}" }
        false
      end
    end
  end
end
