# frozen_string_literal: true

#
# Handles log frame persistence for a resource acording to plan limits.
#
class LogFramesManager < ApplicationService
  def initialize(resource, params)
    @resource = resource
    @params = params
    @max_log_messages = Heroku::Plan::CONFIGURED_PLANS.dig(@resource.plan, :max_log_messages) || 1_000
  end

  #
  # Creates and deletes log frames for the resource according to the current plan.
  #
  # @return [true, false] to notify the caller if the method executed successfully or not.
  #
  def call
    LogFrame.transaction do
      @log_frame = @resource.log_frames.create!(@params)
      return true unless limit_exceeded?
      enforce_limit!
    end
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.warn { "LogFramesManager: duplicated frame!" }
    true
  rescue => e
    Rails.logger.error { "LogFramesManager, unexpected error: #{e.message}" }
    false
  end

  private

  #
  # Returns whether the resource exceeds the maximum permitted by the current plan.
  #
  # @return [true, false]
  #
  def limit_exceeded?
    return true if @resource.log_messages_count > @max_log_messages
    false
  end

  #
  # Deletes older log frames when the total messages count exceeds the limit, keeping at least the maximum set.
  #
  def enforce_limit!
    selected = []
    log_frames = @resource.log_frames.where.not(id: @log_frame.id).order(:created_at)
    log_frames.each do |log_frame|
      break if (@resource.log_messages_count - selected.map(&:message_count).sum) <= @max_log_messages
      selected.push log_frame
    end
    LogFrame.where(resource_id: @resource.id, id: selected.map(&:id)).delete_all
    true
  end
end
