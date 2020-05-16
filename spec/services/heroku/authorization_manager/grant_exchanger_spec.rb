# frozen_string_literal: true

require "rails_helper"

describe Heroku::AuthorizationManager::GrantExchanger, type: :service do
  describe "#call" do
    let(:result) { described_class.call(resource) }

    context "when the resource already has tokens" do
      let(:resource) { create :resource, :with_tokens, state: "provisioning" }

      it "returns true" do
        expect(result).to be(true)
      end
    end

    context "when the resource doesn't has tokens" do
      let(:resource) { create :resource, state: "provisioning" }

      before do
        stub_request(:post, Heroku::AuthorizationManager::BASE_URL).to_return(
          body: response_body,
          status: response_status,
          headers: {"Content-Type" => "application/json"}
        )
      end

      context "with a successful request to the identity provider" do
        let(:response_body) do
          {
            access_token: FFaker::Guid.guid.downcase,
            refresh_token: FFaker::Guid.guid.downcase,
            expires_in: 28_800,
            token_type: "Bearer"
          }.to_json
        end
        let(:response_status) { 200 }

        it "returns true" do
          expect(result).to be(true)
        end

        it "updates the resource" do
          expect(result && resource.reload.refresh_token.present?).to be(true)
        end
      end

      context "with an unsuccessful request to the identity provider" do
        let(:response_body) do
          {
            id: "unauthorized",
            message: "OAuth authorization invalid."
          }.to_json
        end
        let(:response_status) { 401 }

        it "returns false" do
          expect(result).to be(false)
        end

        it "doesn't updates the resource" do
          expect(result || resource.reload.refresh_token.present?).to be(false)
        end
      end
    end
  end
end
