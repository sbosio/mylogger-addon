# frozen_string_literal: true

#
# Models log frames linked to an active resource.
#
class LogFrame < ApplicationRecord
  #
  # Associations.
  #
  belongs_to :resource, inverse_of: :log_frames

  #
  # Validations.
  #
  validates :resource, :message_count, :external_id, :frame_content, presence: true
  validate :check_frame_content

  #
  # Lockbox encrypted attributes.
  #
  encrypts :frame_content

  #
  # Parses the frame content and returns an array of `LogMessage` instances initialized from the frame content.
  #
  def log_messages
    @log_messages ||= parse_frame_content
  rescue => e
    Rails.logger.error { "LogFrame#log_messages: #{e.message}." }
  end

  private

  #
  # Checks whether the frame content is valid or not.
  #
  def check_frame_content
    errors.add(:frame_content, "couldn't be parsed as it had an incorrect format") unless log_messages.try(:size) == message_count
  end

  #
  # Parses the frame content and maps it to an array of LogMessage instances.
  #
  # @return [Array<LogMessage>] an array of `LogMessage` instances.
  #
  def parse_frame_content
    messages = []
    rest = frame_content.dup
    loop do
      _match, length, rest = rest.match(/\A(\d+) (.*)\Z/m).to_a
      break unless length.present?

      message, rest = rest.unpack("a#{length}a*")
      messages.push LogMessage.create!(message)
    end
    messages
  end
end
