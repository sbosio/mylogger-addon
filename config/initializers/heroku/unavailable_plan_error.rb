# frozen_string_literal: true

module Heroku
  #
  # Error class to raise when an unexistent/inactive plan tries to be provisioned.
  #
  class UnavailablePlanError < StandardError
    def message
      I18n.t("heroku.error_messages.unavailable_plan")
    end
  end
end
