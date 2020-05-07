# frozen_string_literal: true

module Heroku
  #
  # Job that handles background (asynchronous) provisioning.
  #
  # @raise [Heroku::ProvisioningError] if some provisioning step failed.
  #
  class ProvisioningJob < ApplicationJob
    def perform(resource_id)
      resource = Resource.find resource_id
      raise Heroku::ProvisioningError unless Heroku::ProvisioningManager::ResourceProvisioner.call(resource)
    end
  end
end
