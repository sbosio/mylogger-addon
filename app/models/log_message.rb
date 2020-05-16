# frozen_string_literal: true

#
# Non-persisted model to ease the handling of log messages inside a `LogFrame` instance.
#
class LogMessage
  include ActiveModel::Model

  #
  # Logplex messages format.
  #
  MESSAGE_FORMAT = %r{\A<(\d+)>\d+ ([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+) - (.*)\Z}m

  #
  # Attributes
  #
  attr_reader :priority, :timestamp, :host, :application, :process, :message

  #
  # Returns a new instance of LogMessage.
  #
  # @param [String] logplex_message a string containing a single Logplex formatted log message.
  #
  def initialize(logplex_message)
    fields = logplex_message.match(MESSAGE_FORMAT).to_a

    @priority = fields[1].to_i
    @timestamp = Time.parse(fields[2])
    @host = fields[3]
    @application = fields[4]
    @process = fields[5]
    @message = fields[6]
  end

  #
  # Emulate `create!` class method from ActiveRecord::Base.
  #
  # @return [LogMessage] self
  #
  def self.create!(logplex_message)
    new(logplex_message).save!
  end

  #
  # Validations
  #
  validates :priority, :timestamp, :host, :application, :process, :message, presence: true
  validates :priority, numericality: {integer: true}

  #
  # Emulate `save!` method from ActiveRecord::Base.
  #
  # @return [LogMessage] self
  # @raise [ActiveRecord::RecordInvalid] if the initialization argument hasn't the expected format.
  #
  def save!
    raise ActiveRecord::RecordInvalid unless valid?

    self
  end
end
