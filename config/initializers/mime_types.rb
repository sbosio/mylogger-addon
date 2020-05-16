# frozen_string_literal: true

module Heroku
  #
  # Handles Heroku's mime types installation.
  #
  class MimeType
    #
    # MIME type used by Heroku Addon Partner API version 3.
    #
    ADDON_PARTNER_API = "application/vnd.heroku-addons+json; version=3"

    #
    # MIME type used by Heroku Platform API version 3.
    #
    PLATFORM_API = "application/vnd.heroku+json; version=3"

    class << self
      #
      # Handles Heroku's mime types installation.
      #
      # @return [nil]
      #
      def install
        Mime::Type.register ADDON_PARTNER_API, :addon_partner_api
        Mime::Type.register PLATFORM_API, :platform_api

        parsers = ActionDispatch::Request.parameter_parsers.merge(
          Mime::Type.lookup(ADDON_PARTNER_API).symbol => decode_json,
          Mime::Type.lookup(PLATFORM_API).symbol => decode_json
        )
        ActionDispatch::Request.parameter_parsers = parsers
        nil
      end

      #
      # Returns an anonymous Proc that handles JSON decodification of request's body.
      #
      def decode_json
        lambda do |body|
          ActiveSupport::JSON.decode(body).with_indifferent_access
        end
      end
    end
  end
end

# Install Heroku's MIME types
Heroku::MimeType.install
