# frozen_string_literal: true

module Heroku
  #
  # Error class to raise when any of the provisioning steps fails.
  #
  class DeprovisioningError < StandardError
    def message
      "The attempt to deprovision the resource failed. See previous log messages."
    end
  end
end
