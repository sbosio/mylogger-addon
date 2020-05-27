# frozen_string_literal: true

FactoryBot.define do
  factory :log_frame do
    transient do
      hostname { FFaker::Internet.domain_name }
      appname { FFaker::Product.brand }
      procname { "web.1" }
    end

    resource { create :resource }
    message_count { Random.rand(1..10) }
    external_id { FFaker::Guid.guid.downcase }
    frame_content do
      messages = []
      (1..message_count).each do |message_index|
        messages << build_message(message_index)
      end
      messages.map { |m| "#{m.bytesize} #{m}" }.join
    end
    created_at { Time.current }
    updated_at { created_at }

    trait :with_invalid_format do
      frame_content do
        messages = []
        (1..message_count).each do |message_index|
          messages << FFaker::Lorem.sentences(Random.rand(1..3)).join("\n") + "\n"
        end
        messages.map { |m| "#{m.bytesize} #{m}" }.join
      end
    end
  end
end

def build_message(index)
  message = "<40>1 "
  message += (Time.current - index.seconds).iso8601.gsub("Z", "+00:00")
  message += " #{hostname} #{appname} #{procname} - "
  message + FFaker::Lorem.sentences(Random.rand(1..3)).join("\n") + "\n"
end
