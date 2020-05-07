# frozen_string_literal: true

module Heroku
  module AuthorizationManager
    #
    # Refreshes the OAuth access token for a resource.
    #
    class TokenRefresher < ApplicationService
      def initialize(resource)
        @resource = resource
      end

      #
      # Sends the request to refresh the access token and updates resource's data.
      #
      # @return [String, nil] the new access token, or `nil` if it failed to obtain a new token.
      #
      def call
        return nil unless @resource.refresh_token.present?

        @resource.update!(mapped_response_params)
        @resource.access_token
      rescue StandardError => e
        Rails.logger.error { "Heroku::AuthorizationManager::TokenRefresher unexpected error: #{e.message}" }
        nil
      end

      private

      #
      # Parameters for the grant exchange request.
      #
      def payload
        {
          grant_type: 'refresh_token',
          refresh_token: @resource.refresh_token,
          client_secret: Rails.application.credentials.partner_portal_client_secret
        }
      end

      #
      # Parses response parameters and maps them into `Resource` model's attributes.
      #
      def mapped_response_params
        params = JSON.parse(response).with_indifferent_access.freeze
        {
          access_token: params[:access_token],
          access_token_expires_at: Time.current + params[:expires_in].seconds,
          access_token_type: params[:token_type]
        }
      end

      #
      # Sends the request for a new access token and returns the response body if successful.
      #
      # @return [String] containing the response body from the request.
      # @raise [Heroku::AuthorizationManager::TokenRefreshError] if the request didn't succeed.
      #
      def response
        resp = Faraday.post(Heroku::AuthorizationManager::BASE_URL, payload)
        return resp.body if resp.status == 200

        raise Heroku::AuthorizationManager::TokenRefreshError, JSON.parse(resp.body)['message']
      end
    end
  end
end
