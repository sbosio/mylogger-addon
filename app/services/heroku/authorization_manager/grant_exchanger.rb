# frozen_string_literal: true

module Heroku
  module AuthorizationManager
    #
    # Exchanges the grant code provided by Heroku on the provisioning request for OAuth tokens required to authenticate
    # against the Heroku Platform API.
    #
    class GrantExchanger < ApplicationService
      def initialize(resource)
        @resource = resource
      end

      #
      # Sends the request and updates resource's data.
      #
      # @return [true, false] to notify the caller if the method executed successfully or not.
      #
      def call
        return true if @resource.refresh_token.present?

        @resource.update!(mapped_response_params)
        true
      rescue StandardError => e
        Rails.logger.error { "Heroku::AuthorizationManager::GrantExchanger unexpected error: #{e.message}" }
        false
      end

      private

      #
      # Parameters for the grant exchange request.
      #
      def payload
        {
          grant_type: @resource.grant_type,
          code: @resource.grant_code,
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
          access_token_type: params[:token_type],
          refresh_token: params[:refresh_token]
        }
      end

      #
      # Sends the request to exchange the grant and returns the response body if successful.
      #
      # @return [String] containing the response body from the request.
      # @raise [Heroku::AuthorizationManager::GrantExchangeError] if the request didn't succeed.
      #
      def response
        resp = Faraday.post(Heroku::AuthorizationManager::BASE_URL, payload)
        return resp.body if resp.status == 200

        raise Heroku::AuthorizationManager::GrantExchangeError, JSON.parse(resp.body)['message']
      end
    end
  end
end
