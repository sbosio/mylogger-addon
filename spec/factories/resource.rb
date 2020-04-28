# frozen_string_literal: true

FactoryBot.define do
  factory :resource do
    callback_url { "https://api.heroku.com/addons/#{external_id}" }
    name { FFaker::Product.product.downcase.tr(' ', '-') }
    grant_code { FFaker::Guid.guid.downcase }
    grant_expires_at { Time.current + 1.day }
    grant_type { 'authorization_code' }
    options { {} }
    plan { 'test' }
    region { 'amazon-web-services::us-east-1' }
    external_id { FFaker::Guid.guid.downcase }
    log_drain_token { "d.#{FFaker::Guid.guid.downcase}" }
    state { 'pending' }
    created_at { Time.current }
    updated_at { created_at }
  end
end
