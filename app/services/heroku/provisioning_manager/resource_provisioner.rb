# frozen_string_literal: true

module Heroku
  module ProvisioningManager
    #
    # Service object that orchestrates the provisioning of a new resource.
    #
    class ResourceProvisioner < ApplicationService
      def initialize(resource)
        @resource = resource
      end

      #
      # Provisioning a new resource implies three secuential steps that have to succeed:
      #
      # * Exchange the grant code for the OAuth tokens.
      # * Allocate the _physical_ required resources (if any).
      # * Update provisioning state and config vars for the customer's Heroku application.
      #
      # @return [true, false] to notify the caller if the method executed successfully or not.
      #
      def call
        return false unless @resource.provisioning?
        return false unless AuthorizationManager::GrantExchanger.call(@resource)
        return false unless ResourceAllocator.call(@resource)
        return false unless WebhookSubscriber.call(@resource)
        return false unless AddonConfigUpdater.call(@resource)

        @resource.provision_completed!
        true
      rescue => e
        Rails.logger.error { e.message }
        false
      end
    end
  end
end
