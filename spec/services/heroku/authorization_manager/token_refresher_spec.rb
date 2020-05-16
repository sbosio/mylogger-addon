# frozen_string_literal: true

require "rails_helper"

describe Heroku::AuthorizationManager::TokenRefresher, type: :service do
  describe "#call" do
    let(:result) { described_class.call(resource) }

    context "when the resource does not have a refresh token" do
      let(:resource) { create :resource, state: "provisioning" }

      it "returns nil" do
        expect(result).to be(nil)
      end
    end

    context "when the resource has a refresh token" do
      let(:resource) { create :resource, :with_tokens, state: "provisioning" }

      before do
        stub_request(:post, Heroku::AuthorizationManager::BASE_URL).to_return(
          body: response_body,
          status: response_status,
          headers: {"Content-Type" => "application/json"}
        )
      end

      context "with a successful request to the identity provider" do
        let(:original_refresh_token) { resource.refresh_token }
        let(:new_access_token) { FFaker::Guid.guid.downcase }
        let(:response_body) do
          {
            access_token: new_access_token,
            refresh_token: FFaker::Guid.guid.downcase,
            expires_in: 28_800,
            token_type: "Bearer"
          }.to_json
        end
        let(:response_status) { 200 }

        it "returns a new access token" do
          expect(result).to eq(new_access_token)
        end

        it "updates the resource with the new access token" do
          expect(result && resource.reload.access_token).to eq(result)
        end

        it "doesn't updates the refresh token" do
          expect(result && resource.reload.refresh_token).to eq(original_refresh_token)
        end
      end

      context "with an unsuccessful request to the identity provider" do
        let(:original_access_token) { resource.access_token }
        let(:response_body) do
          {
            id: "unauthorized",
            message: "OAuth authorization invalid."
          }.to_json
        end
        let(:response_status) { 401 }

        it "returns nil" do
          expect(result).to be(nil)
        end

        it "doesn't updates the resource" do
          expect(result || resource.reload.access_token).to eq(original_access_token)
        end
      end
    end
  end
end
