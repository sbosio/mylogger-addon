# frozen_string_literal: true

module Logplex
  #
  # Controller that handles log frames sent through the Heroku log drain.
  #
  class LogFramesController < Logplex::ApiController
    before_action :check_header_params
    before_action :set_resource

    #
    # POST /logplex/log_frames
    #
    def create
      head(:unprocessable_entity) && return unless LogFramesManager.call(@resource, create_params)

      head :created
    end

    private

    #
    # Checks if the request has all the required header parameters.
    #
    def check_header_params
      return if %i[drain_token message_count external_id].all? { |k| header_params[k].present? }

      unprocessable_entity
    end

    #
    # Sets the targeted resource if it exists and is active based on the log drain token present in the request headers.
    #
    def set_resource
      @resource = Resource.find_by!(log_drain_token: header_params[:drain_token], state: "provisioned")
    end

    #
    # Returns a hash with the parameters set on the required headers.
    #
    def header_params
      @header_params ||= {
        drain_token: request.headers["Logplex-Drain-Token"],
        message_count: request.headers["Logplex-Msg-Count"],
        external_id: request.headers["Logplex-Frame-Id"]
      }
    end

    #
    # Maps POST request info to LogFrame attributes.
    #
    def create_params
      {
        message_count: header_params[:message_count],
        external_id: header_params[:external_id],
        frame_content: request.raw_post
      }
    end
  end
end
