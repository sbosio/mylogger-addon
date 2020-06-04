# frozen_string_literal: true

module Heroku
  #
  # Class that holds plan configurations.
  #
  class Plan
    CONFIGURED_PLANS = {
      test: {
        name: "Test",
        max_log_messages: 1_000,
        active: true,
        monthly_cents: 0
      }
    }.with_indifferent_access

    def self.available?(plan)
      CONFIGURED_PLANS.dig(plan.to_sym, :active)
    end
  end
end
