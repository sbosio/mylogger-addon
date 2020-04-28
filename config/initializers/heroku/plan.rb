# frozen_string_literal: true

module Heroku
  #
  # Class that holds plan configurations.
  #
  class Plan
    CONFIGURED_PLANS = {
      test: {
        max_log_lines: 1_000,
        active: true
      }
    }.with_indifferent_access.freeze

    def self.available?(plan)
      CONFIGURED_PLANS.dig(plan.to_sym, :active)
    end
  end
end
