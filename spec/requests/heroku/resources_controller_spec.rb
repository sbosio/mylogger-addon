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

    context 'when a resource with the same external id exists' do
      let(:existent_resource) { create :resource, state: resource_state }
      let(:params) do
        {
          callback_url: "https://api.heroku.com/addons/#{existent_resource.external_id}",
          name: existent_resource.name,
          oauth_grant: {
            code: existent_resource.grant_code,
            expires_at: existent_resource.grant_expires_at,
            type: existent_resource.grant_type
          },
          options: {},
          plan: existent_resource.plan,
          region: existent_resource.region,
          uuid: existent_resource.external_id,
          log_drain_token: existent_resource.log_drain_token
        }
      end

      context 'with a provisioning state' do
        let(:resource_state) { 'provisioning' }

        it 'returns an accepted status code' do
          expect(response).to be_accepted
        end
      end

      context 'with a provisioned state' do
        let(:resource_state) { 'provisioned' }

        it 'returns an accepted status code' do
          expect(response).to be_accepted
        end
      end

      context 'with an invalid state for provisioning' do
        let(:resource_state) { 'deprovisioning' }

        it 'returns an unprocessable entity status code' do
          expect(response).to be_unprocessable
        end
      end
    end
  end

  describe '#destroy (deprovisioning)' do
    let(:resource) { create :resource, state: 'provisioned' }
    let(:endpoint) { "/heroku/resources/#{resource.external_id}" }
    let(:method) { 'delete' }
    let(:params) { nil }

    it_behaves_like 'an endpoint that requires basic auth'

    context 'when the resource is still provisioned' do
      it 'returns a no content status code' do
        expect(response).to be_no_content
      end
    end

    context 'when the resource was already deprovisioned' do
      let(:resource) { create :resource, state: 'deprovisioned' }

      it 'returns a no content status code' do
        expect(response).to be_no_content
      end
    end
  end
end
