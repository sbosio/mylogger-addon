# frozen_string_literal: true

module Heroku
  module ProvisioningManager
    #
    # Service object that allocates physical resources required for provisioning.
    #
    class ResourceAllocator < ApplicationService
      def initialize(resource)
        @resource = resource
      end

      #
      # For this demo add-on there aren't physical resources to allocate, so we just return `true`.
      # But when dealing with other types of add-ons, this will be the place to allocate the physical
      # resources needed (database creation, disk quota allocation, etc.)
      #
      def call
        true
      end
    end
  end
end
