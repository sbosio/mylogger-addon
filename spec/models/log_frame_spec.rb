# frozen_string_literal: true

require "rails_helper"

describe LogFrame, type: :model do
  subject { build :log_frame }

  describe "validations" do
    it { is_expected.to validate_presence_of(:resource) }
    it { is_expected.to validate_presence_of(:message_count) }
    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:frame_content) }
  end

  describe "#log_messages" do
    let(:log_frame) { create :log_frame }

    it "returns an array with a size that equals the `messages_count` attribute value" do
      expect(log_frame.log_messages.size).to eq(log_frame.message_count)
    end
  end
end
