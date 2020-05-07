# frozen_string_literal: true

require 'rails_helper'

describe Resource, type: :model do
  subject { build :resource }

  describe 'validations' do
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

  describe '#fresh_token' do
    let(:resource) { create :resource, :with_tokens, access_token_expires_at: expiration_time, state: 'provisioned' }

    context "when the access token hasn't expired" do
      let(:expiration_time) { Time.current + 3.hours }

      it 'returns the current access token' do
        expect(resource.fresh_token).to eq(resource.access_token)
      end
    end

    context 'when the access token has expired' do
      let(:expiration_time) { Time.current - 30.minutes }
      let(:token_refresher_result) { FFaker::Guid.guid.downcase }

      before do
        allow(Heroku::AuthorizationManager::TokenRefresher).to receive(:call).and_return(token_refresher_result)
      end

      it 'calls token refresher service object' do
        resource.fresh_token
        expect(Heroku::AuthorizationManager::TokenRefresher).to have_received(:call)
      end

      it 'returns a new access token' do
        expect(resource.fresh_token).not_to eq(resource.access_token)
      end
    end
  end
end
