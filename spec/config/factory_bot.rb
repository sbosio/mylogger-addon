# frozen_string_literal: true

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  #
  # Load all factory definitions before starting the test suite.
  #
  config.before(:suite) do
    FactoryBot.find_definitions
  end
end
