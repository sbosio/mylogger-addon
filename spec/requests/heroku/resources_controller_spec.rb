# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_examples/basic_auth'

describe Heroku::ResourcesController, type: :request do
  let(:content_type) { Heroku::MimeType::ADDON_PARTNER_API }
  let(:headers) do
    {
      'ACCEPT' => content_type,
      'AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user_name, password)
    }
  end
  let(:password) { ENV['MANIFEST_PASSWORD'] || raise('MANIFEST_PASSWORD is undefined, see file ".env.template"') }
  let(:user_name) { ENV['MANIFEST_ID'] || raise('MANIFEST_ID is undefined, see file ".env.template"') }

  before do
    public_send method.to_s, endpoint, params: params, headers: headers
  end

  describe '#create (provisioning)' do
    let(:endpoint) { '/heroku/resources' }
    let(:external_id) { FFaker::Guid.guid.downcase }
    let(:method) { 'post' }
    let(:params) do
      {
        callback_url: "https://api.heroku.com/addons/#{external_id}",
        name: FFaker::Product.product.downcase.tr(' ', '-'),
        oauth_grant: {
          code: FFaker::Guid.guid.downcase,
          expires_at: Time.current + 1.day,
          type: 'authorization_code'
        },
        options: {},
        plan: plan,
        region: 'amazon-web-services::us-east-1',
        uuid: external_id,
        log_drain_token: "d.#{FFaker::Guid.guid.downcase}"
      }
    end
    let(:plan) { 'test' }

    it_behaves_like 'an endpoint that requires basic auth'

    context 'with an active plan' do
      it 'returns an accepted status code' do
        expect(response).to be_accepted
      end
    end

    context 'with an unexistent plan' do
      let(:plan) { SecureRandom.uuid }

      it 'returns an unprocessable entity status code' do
        expect(response).to be_unprocessable
      end
    end
  end

  describe '#destroy (deprovisioning)' do
    let(:resource) { create :resource }
    let(:endpoint) { "/heroku/resources/#{resource.external_id}" }
    let(:method) { 'delete' }
    let(:params) { nil }

    it_behaves_like 'an endpoint that requires basic auth'

    it 'returns a no content status code' do
      expect(response).to be_no_content
    end
  end
end
