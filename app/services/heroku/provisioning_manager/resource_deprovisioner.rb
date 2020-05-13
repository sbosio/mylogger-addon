# frozen_string_literal: true

module Heroku
  module ProvisioningManager
    #
    # Service object that deprovisions an active resource.
    #
    class ResourceDeprovisioner < ApplicationService
      def initialize(resource)
        @resource = resource
      end

      #
      # Deprovisioning an active resource implies removing all log messages linked with this resource
      # and updating its state.
      #
      # @return [true, false] to notify the caller if the method executed successfully or not.
      #
      def call
        return false unless @resource.deprovisioning?

        ActiveRecord::Base.transaction do
          @resource.log_frames.delete_all
          @resource.deprovision_completed!
        end
        true
      rescue StandardError => e
        Rails.logger.error { e.message }
        false
      end
    end
  end
end
