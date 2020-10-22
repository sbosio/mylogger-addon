# frozen_string_literal: true

require "rails_helper"

describe Heroku::ProvisioningManager::WebhookSubscriber, type: :service do
  describe "#call" do
    let(:endpoint) { platform_api_url + "/addons/#{resource.external_id}/webhooks" }
    let(:platform_api_url) { PlatformAPI.send(:default_options)[:url] }
    let(:resource) { create :resource, :with_tokens, state: "provisioning" }
    let(:result) { described_class.call(resource) }

    before do
      stub_request(:post, endpoint).to_return(
        body: response_body,
        status: response_status,
        headers: {"Content-Type" => Heroku::MimeType::PLATFORM_API}
      )
    end

    context "when the request to Platform API succeeds" do
      let(:response_body) { {}.to_json }
      let(:response_status) { 200 }

      it "returns true" do
        expect(result).to be(true)
      end
    end

    context "when the request to Platform API fails" do
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
    end
  end
end
