# frozen_string_literal: true

RSpec.configure do |config|
  #
  # Truncate all tables before start and load required seeds.
  # Use transactions to keep database state between examples.
  #
  config.before :suite do
    DatabaseCleaner.clean_with(:truncation)
    Rails.application.load_seed
    DatabaseCleaner.strategy = :transaction
  end

  #
  # Run each example inside a transaction block to keep the database state.
  #
  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
