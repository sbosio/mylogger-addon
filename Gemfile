# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.6.6"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 5.2.4", ">= 5.2.4.3"

# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"

# Use Puma as the app server
gem "puma", "~> 3.11"

# Use ActiveModel has_secure_password
gem "bcrypt", "~> 3.1.7"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.1.0", require: false

# Use Fast JSON API for serialization.
gem "fast_jsonapi"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

# State machines
gem "state_machines-activerecord"

# DelayedJob for background (asynchronous) processing
gem "delayed_job_active_record"

# Faraday for making API requests
gem "faraday"

# Lockbox to encrypt data
gem "lockbox"

# Heroku Platform API Ruby client
gem "platform-api"

# Gems for our dashboard
gem "bootstrap"
gem "font_awesome5_rails"
gem "jquery-datatables"
gem "jquery-easing-rails"
gem "jquery-rails"

# FlockSynchronize for process synchronization
gem "flock_synchronize"

# Why using ERB templates for HTML when you have HAML?
gem "haml"

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "dotenv-rails"
  gem "ffaker"
  gem "pry-byebug"
  gem "pry-doc"
  gem "pry-rails"
end

group :development do
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "rails_best_practices"
  gem "ripper-tags"
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rspec"
  gem "solargraph"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "standard", "~> 0.4"
  gem "yard"
end

group :test do
  gem "database_cleaner"
  gem "factory_bot"
  gem "fuubar"
  gem "rails-controller-testing"
  gem "rspec"
  gem "rspec-rails"
  gem "should_not"
  gem "shoulda-matchers"
  gem "simplecov"
  gem "state_machines-rspec"
  gem "webmock"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
