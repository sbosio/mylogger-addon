# frozen_string_literal: true

FactoryBot.define do
  factory :log_frame do
    transient do
      hostname { FFaker::Internet.domain_name }
    end

    resource { create :resource }
    message_count { Random.rand(1..10) }
    external_id { FFaker::Guid.guid.downcase }
    frame_content do
      messages = []
      (1..message_count).each do |message_index|
        messages << build_message(message_index)
      end
      messages.map do |message|
        "#{message.length} #{message}"
      end.join("\n")
    end
  end
end

def build_message(index)
  message = '<40>1 '
  message += (Time.current - index.seconds).iso8601 + ' '
  message += hostname
  message += ' app web.1 - '
  message + FFaker::Lorem.sentence
end
