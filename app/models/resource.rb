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
      transition %i[deprovisioning deprovisioned] => same
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
  # @return [Integer] count of log messages
  #
  def log_messages_count
    @log_messages_count ||= log_frames.sum(:message_count)
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
