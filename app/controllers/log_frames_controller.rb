# frozen_string_literal: true

#
# Controller that handles log frames sent through the Heroku log drain.
#
class LogFramesController < ApplicationController
  before_action :set_resource

  #
  # POST /log_frames
  #
  def create
    head(:unprocessable_entity, content_length: 0) && return unless LogFramesManager.call(@resource, create_params)

    head :created, content_length: 0
  end

  private

  #
  # Sets the targeted resource if it exists and is active based on the log drain token present in the request headers.
  #
  def set_resource
    head(:unsupported_media_type, content_length: 0) && return unless request.headers["Content-Type"] == "application/logplex-1"

    @resource = Resource.find_by(log_drain_token: header_params[:drain_token], state: "provisioned")
    head(:unprocessable_entity, content_length: 0) unless @resource.present?
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
