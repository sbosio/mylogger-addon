# frozen_string_literal: true

require "rails_helper"

describe Resource, type: :model do
  subject { build :resource }

  describe "validations" do
    it { is_expected.to validate_presence_of(:callback_url) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:grant_code) }
    it { is_expected.to validate_presence_of(:grant_expires_at) }
    it { is_expected.to validate_presence_of(:grant_type) }
    it { is_expected.to validate_presence_of(:plan) }
    it { is_expected.to validate_presence_of(:log_drain_token) }
    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_uniqueness_of(:external_id).case_insensitive }
  end

  describe "#fresh_access_token" do
    let(:resource) { create :resource, :with_tokens, access_token_expires_at: expiration_time, state: "provisioned" }

    context "when the access token hasn't expired" do
      let(:expiration_time) { Time.current + 3.hours }

      it "returns the current access token" do
        expect(resource.fresh_access_token).to eq(resource.access_token)
      end
    end

    context "when the access token has expired" do
      let(:expiration_time) { Time.current - 30.minutes }
      let(:token_refresher_result) { FFaker::Guid.guid.downcase }
      let(:original_access_token) { resource.access_token }

      before do
        allow(Heroku::AuthorizationManager::TokenRefresher).to receive(:call).and_return(token_refresher_result)
      end

      it "calls token refresher service object" do
        resource.fresh_access_token
        expect(Heroku::AuthorizationManager::TokenRefresher).to have_received(:call)
      end

      it "returns a new access token" do
        expect(resource.fresh_access_token).not_to eq(original_access_token)
      end
    end
  end

  describe "#log_messages_count" do
    let(:resource) { create :resource, :with_tokens, state: "provisioned" }
    let(:another_resource) { create :resource, :with_tokens, state: "provisioned" }
    let(:log_frames) { create_list(:log_frame, Random.rand(0..5), resource: resource) }
    let(:other_log_frames) { create_list(:log_frame, Random.rand(0..5), resource: another_resource) }

    it "returns the correct count" do
      log_messages_count = log_frames.map(&:message_count).sum
      expect(resource.log_messages_count).to eq(log_messages_count)
    end
  end

  describe "#log_messages" do
    let(:resource) { create :resource, :with_tokens, state: "provisioned" }
    let(:log_frames) { create_list(:log_frame, Random.rand(0..5), resource: resource) }

    it "returns an array with a size equal to the total count of log messages" do
      log_messages_count = log_frames.map(&:message_count).sum
      expect(resource.log_messages.size).to eq(log_messages_count)
    end
  end

  describe "#average_retention" do
    let(:resource) { create :resource, :with_tokens, state: "provisioned" }
    let(:older_log_frame) { create :log_frame, resource: resource, created_at: Time.new(2020, 4, 25, 12) }
    let(:newer_log_frame) { create :log_frame, resource: resource }

    it "returns the correct amount of seconds" do
      allow(Time).to receive(:current).and_return(Time.new(2020, 4, 25, 12, 10))
      log_messages_count = older_log_frame.message_count + newer_log_frame.message_count
      expect(resource.average_retention).to eq(1_000 * 600 / log_messages_count)
    end
  end
end
