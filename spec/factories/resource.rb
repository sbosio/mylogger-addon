# frozen_string_literal: true

FactoryBot.define do
  factory :resource do
    callback_url { "https://api.heroku.com/addons/#{external_id}" }
    name { FFaker::Product.product.downcase.tr(' ', '-') }
    grant_code { FFaker::Guid.guid.downcase }
    grant_expires_at { Time.current + 5.minutes }
    grant_type { 'authorization_code' }
    options { {} }
    plan { 'test' }
    region { 'amazon-web-services::us-east-1' }
    external_id { FFaker::Guid.guid.downcase }
    log_drain_token { "d.#{FFaker::Guid.guid.downcase}" }
    state { 'pending' }
    created_at { Time.current }
    updated_at { created_at }

    trait :with_tokens do
      access_token { FFaker::Guid.guid.downcase }
      access_token_expires_at { Time.current + 8.hours }
      access_token_type { 'Bearer' }
      refresh_token { FFaker::Guid.guid.downcase }
    end
  end
end
