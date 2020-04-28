# frozen_string_literal: true

module Heroku
  #
  # Error class to raise when requests don't have Basic Auth credentials or they are wrong.
  #
  class NotAuthorizedError < StandardError; end
end
