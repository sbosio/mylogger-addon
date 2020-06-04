# frozen_string_literal: true

module Sso
  #
  # Heroku SSO session management.
  #
  class SessionsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: :create
    skip_before_action :authenticate_sso_login!, only: :create
    before_action :check_login_params, only: :create
    before_action :set_resource, only: :create

    #
    # POST '/sso/login'
    #
    def create
      forbidden && return unless fresh_token? && valid_token?

      session[:resource_id] = @resource.id
      redirect_to dashboard_path
    end

    #
    # DELETE '/sso/log_out'
    #
    def destroy
      session[:resource_id] = nil
      render :destroy, layout: false
    end

    private

    #
    # Check SSO login params are present or render a forbidden response.
    #
    def check_login_params
      forbidden unless %i[resource_id resource_token timestamp].all? { |s| params.key?(s) }
    end

    #
    # Returns whether the timestamp at which the token was generated differs or not in 5 minutes from current time.
    #
    # @return [true, false]
    #
    def fresh_token?
      params[:timestamp].to_i > (Time.current - 5.minutes).to_i
    end

    #
    # Sets the target resource based on the SSO login params.
    # Forbids access if the resource doesn't exists or isn't active.
    #
    def set_resource
      @resource = Resource.with_state(:provisioned).find_by!(external_id: params[:resource_id])
    end

    #
    # Returns whether the token set matches the calculated one based on the shared `sso_salt` secret and the timestamp,
    # plus if it's referencing an active (_provisioned_) resource.
    #
    # @return [true, false]
    #
    def valid_token?
      pre_token = params[:resource_id] + ":" + Rails.application.credentials.sso_salt + ":" + params[:timestamp]
      params[:resource_token] == Digest::SHA1.hexdigest(pre_token)
    end
  end
end
