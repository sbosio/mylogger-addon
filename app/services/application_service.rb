# frozen_string_literal: true

#
# Base class inherited by all object services.
#
class ApplicationService
  #
  # Convenience method to allow `call` directly on the class for readability.
  #
  def self.call(*args, &block)
    new(*args, &block).call
  end
end
