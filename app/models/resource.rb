# frozen_string_literal: true

#
# Class to model resource instances.
#
class Resource < ApplicationRecord
  #
  # Associations.
  #
  has_many :log_frames, inverse_of: :resource, dependent: :destroy

  #
  # Validations.
  #
  validates :callback_url, :name, :grant_code, :grant_expires_at, :grant_type, :plan, :log_drain_token, :state, presence: true
  validates :external_id, presence: true, uniqueness: {case_sensitive: false}

  #
  # Lockbox encrypted attributes.
  #
  encrypts :grant_code, :access_token, :refresh_token

  #
  # Verify that the requested plan is still available or raise an exception.
  #
  before_create :check_plan_availability!

  #
  # This machine models provisioning states and valid transitions for a resource life cycle.
  #
  state_machine :state, initial: :pending do
    event :provision do
      transition pending: :provisioning
      transition %i[provisioning provisioned] => same
    end
    after_transition to: :provisioning, do: :provision_resource
    event :provision_completed do
      transition provisioning: :provisioned
    end
    event :deprovision do
      transition provisioned: :deprovisioning
      transition deprovisioning: same
    end
    after_transition to: :deprovisioning, do: :deprovision_resource
    event :deprovision_completed do
      transition deprovisioning: :deprovisioned
    end
    event :failure do
      transition provisioning: :provision_failed
      transition deprovisioning: :deprovision_failed
    end
  end

  #
  # Returns a fresh OAuth access token.
  #
  # @return [String, nil] a fresh OAuth access token or `nil` if it was expired and we couldn't refresh it.
  #
  def fresh_access_token
    return access_token unless access_token_expired?

    Heroku::AuthorizationManager::TokenRefresher.call(self)
  end

  #
  # Returns the count of log messages stored for this resource.
  #
  # @param refresh [Boolean] if `true` the count will be recalculated even if it was already memoized.
  #
  # @return [Integer] count of log messages
  #
  def log_messages_count(refresh: false)
    return @log_messages_count if @log_messages_count.present? && !refresh

    @log_messages_count = log_frames.sum(:message_count)
  end

  #
  # Returns an array with all `LogMessage` instances for this resource.
  #
  # @return [Array<LogMessage>] all log messages for this resource.
  #
  def log_messages
    log_frames.order(:created_at).map(&:log_messages).flatten
  end

  #
  # Returns the average interval of retention for log frames, expresed in seconds.
  #
  # @return [Integer] total number of seconds.
  #
  def average_retention
    log_frames_timespan = Time.current - (log_frames.minimum(:created_at) || created_at)
    log_messages_per_second = log_messages_count / log_frames_timespan
    return (max_log_messages * 1_000) if log_messages_per_second.zero?

    (max_log_messages / log_messages_per_second).to_i
  end

  private

  #
  # Checks the availability of the requested `plan`.
  #
  # @raise [Heroku::UnavailablePlanError] if the plan isn't configured or it's inactive and resource is in an active state.
  #
  def check_plan_availability!
    return if state.starts_with?("deprovision")
    raise Heroku::UnavailablePlanError unless Heroku::Plan.available?(plan)
  end

  #
  # Enqueues a job for deprovisioning.
  #
  def deprovision_resource
    Heroku::DeprovisioningJob.perform_later id
  end

  #
  # Returns this resource's max log messages limit according to the configured plan.
  #
  # @return [Integer] plan max log messages.
  #
  def max_log_messages
    Heroku::Plan::CONFIGURED_PLANS.dig(plan, :max_log_messages)
  end

  #
  # Enqueues a job for provisioning.
  #
  def provision_resource
    Heroku::ProvisioningJob.perform_later id
  end

  #
  # Tells whether the access token is almost expired (1 minute threshold).
  #
  # @return [true, false]
  #
  def access_token_expired?
    access_token.blank? || access_token_expires_at < Time.current + 1.minute
  end
end
