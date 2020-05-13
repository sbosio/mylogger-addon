# frozen_string_literal: true

module Heroku
  #
  # Job that handles background (asynchronous) deprovisioning.
  #
  # @raise [Heroku::DeprovisioningError] if some provisioning step failed.
  #
  class DeprovisioningJob < ApplicationJob
    def perform(resource_id)
      resource = Resource.find resource_id
      raise Heroku::DeprovisioningError unless Heroku::ProvisioningManager::ResourceDeprovisioner.call(resource)
    end
  end
end
