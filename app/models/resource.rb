# frozen_string_literal: true

#
# Class to model resource instances.
#
class Resource < ApplicationRecord
  #
  # Validations.
  #
  validates :callback_url, :name, :grant_code, :grant_expires_at, :grant_type, :plan, :log_drain_token, :state, presence: true
  validates :external_id, presence: true, uniqueness: true

  #
  # Verify that the requested plan is still available or raise.
  #
  before_commit :check_plan_availability!

  #
  # This machine models provisioning states and valid transitions for a resource life cycle.
  #
  state_machine :state, initial: :pending do
    event :provision do
      transition pending: :provisioning
      transition provisioning: same
    end
    after_transition to: :provisioning, do: :provision_resource
    event :provision_complete do
      transition provisioning: :provisioned
    end
    event :deprovision do
      transition provisioned: :deprovisioning
      transition deprovisioning: same
    end
    after_transition to: :deprovisioning, do: :deprovision_resource
    event :deprovision_complete do
      transition deprovisioning: :deprovisioned
    end
    event :failure do
      transition provisioning: :provision_failed
      transition deprovisioning: :deprovision_failed
    end
  end

  private

  #
  # Checks the availability of the requested `plan`.
  #
  # @raise [Heroku::UnavailablePlanError] if the plan isn't configured or it's inactive and resource is in an active state.
  #
  def check_plan_availability!
    return if state.starts_with?('deprovision')
    raise Heroku::UnavailablePlanError unless Heroku::Plan.available?(plan)
  end

  def deprovision_resource; end

  def provision_resource; end
end
