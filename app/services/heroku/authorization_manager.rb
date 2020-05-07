# frozen_string_literal: true

module Heroku
  module AuthorizationManager
    BASE_URL = 'https://id.heroku.com/oauth/token'

    class GrantExchangeError < StandardError; end
    class TokenRefreshError < StandardError; end
  end
end
