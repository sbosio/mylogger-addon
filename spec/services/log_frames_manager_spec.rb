# frozen_string_literal: true

require "rails_helper"

describe LogFramesManager, type: :service do
  describe "#call" do
    let(:external_id) { log_frame.external_id }
    let(:frame_content) { log_frame.frame_content }
    let(:log_frame) { build :log_frame }
    let(:message_count) { log_frame.message_count }
    let(:params) do
      {
        external_id: external_id,
        message_count: message_count,
        frame_content: frame_content
      }
    end
    let(:resource) { create :resource, :with_tokens, state: "provisioned" }
    let(:result) { described_class.call(resource, params) }

    context "when all params are valid" do
      it "returns true" do
        expect(result).to be(true)
      end

      it "creates a log frame record for the targeted resource" do
        result
        expect(resource.log_frames.count).to eq(1)
      end
    end

    context "when params belong to a duplicated request received" do
      let(:log_frame) { resource.log_frames.first.dup }

      before do
        create :log_frame, resource_id: resource.id
      end

      it "returns true" do
        expect(result).to be(true)
      end

      it "doesn't creates a new log frame record for the resource" do
        expect { result }.not_to change { resource.log_frames.count }
      end
    end

    context "when plan limit is reached" do
      let(:log_frame) { build :log_frame, message_count: 11, created_at: newer_log_frame.created_at + 10.seconds }
      let(:newer_log_frame) do
        create :log_frame, resource_id: resource.id,
                           message_count: 5,
                           created_at: older_log_frame.created_at + 10.seconds
      end
      let(:older_log_frame) { create :log_frame, resource_id: resource.id, message_count: 5, created_at: Time.now - 1.minute }

      before do
        allow(Heroku::Plan::CONFIGURED_PLANS).to receive(:dig).and_return(10)
      end

      it "drops all older log frames keeping at least the maximum set by the plan" do
        result
        expect(LogFrame.where(id: [older_log_frame.id, newer_log_frame.id]).count).to be_zero
      end
    end

    context "when the frame content doesn't have the correct format" do
      let(:frame_content) { FFaker::Lorem.sentences(Random.rand(1..5)).join("\n") }

      it "returns false" do
        expect(result).to be(false)
      end

      it "doesn't create a log frame record for the targeted resource" do
        result
        expect(resource.log_frames.count).to eq(0)
      end
    end

    context "when the log messages have an incorrect format" do
      let(:frame_content) { build(:log_frame, :with_invalid_format, message_count: message_count).frame_content }

      it "returns false" do
        expect(result).to be(false)
      end

      it "doesn't create a log frame record for the targeted resource" do
        result
        expect(resource.log_frames.count).to eq(0)
      end
    end
  end
end
