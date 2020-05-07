# frozen_string_literal: true

module Heroku
  #
  # Resources controller actions for Heroku's provisioning and deprovisioning endpoints.
  #
  class ResourcesController < ApplicationController
    include ActionController::HttpAuthentication::Basic
    before_action :authenticate!

    #
    # POST '/heroku/resources'
    #
    def create
      @resource = Resource.create_with(mapped_params).find_or_create_by!(external_id: resource_params[:uuid])

      begin
        @resource.provision!
        status = :accepted
      rescue StateMachines::InvalidTransition
        status = :unprocessable_entity
      end

      render json: build_response.to_json, status: status, content_type: Heroku::MimeType::ADDON_PARTNER_API
    end

    #
    # DELETE '/heroku/resources/:id'
    #
    def destroy
      @resource = Resource.find_by!(external_id: params[:id])

      begin
        @resource.deprovision!
        status = :no_content
      rescue StateMachines::InvalidTransition
        status = :gone
      end

      head status, content_type: Heroku::MimeType::ADDON_PARTNER_API
    end

    private

    #
    # Handles HTTP Basic Authentication
    #
    # @raise [Heroku::NotAuthorizedError] if there were no credentials present or they were wrong.
    #
    def authenticate!
      raise NotAuthorizedError unless has_basic_credentials?(request)

      user_name, password = user_name_and_password(request).map(&:strip)
      raise Heroku::NotAuthorizedError unless user_name == ENV['MANIFEST_ID'] && password == ENV['MANIFEST_PASSWORD']
    end

    #
    # Builds a hash with the response for the provisioning request.
    #
    def build_response
      {
        id: @resource.external_id,
        message: I18n.t("heroku.resources.provision_requested_for_#{@resource.state}_resource"),
        log_drain_url: "#{request.protocol}#{request.host_with_port}/logs"
      }
    end

    #
    # Maps sanitized parameters to the Resource model attribute names.
    #
    def mapped_params # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      {
        callback_url: resource_params[:callback_url],
        name: resource_params[:name],
        grant_code: resource_params.dig(:oauth_grant, :code),
        grant_expires_at: resource_params.dig(:oauth_grant, :expires_at),
        grant_type: resource_params.dig(:oauth_grant, :type),
        options: resource_params[:options],
        plan: resource_params[:plan],
        region: resource_params[:region],
        external_id: resource_params[:uuid],
        log_drain_token: resource_params[:log_drain_token]
      }
    end

    #
    # Request's parameters sanitization.
    #
    def resource_params
      @resource_params ||= params.permit(
        :callback_url, :name, :options, :plan, :region, :uuid, :log_drain_token, oauth_grant: %i[code expires_at type]
      )
    end
  end
end
