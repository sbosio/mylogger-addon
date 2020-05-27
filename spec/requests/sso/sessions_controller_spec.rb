# frozen_string_literal: true

require "rails_helper"
require "support/shared_examples/session"

describe Sso::SessionsController, type: :request do
  let(:params) do
    {
      resource_id: resource_id,
      resource_token: resource_token,
      id: resource_id,
      token: resource_token,
      timestamp: timestamp,
      nav_data: {}
    }
  end
  let(:resource) { create :resource, :with_tokens, state: "provisioned" }
  let(:resource_id) { resource.external_id }
  let(:resource_token) do
    pre_token = resource_id + ":" + Rails.application.credentials.sso_salt + ":" + timestamp
    Digest::SHA1.hexdigest(pre_token)
  end
  let(:timestamp) { (Time.current - 2.seconds).to_i.to_s }

  describe "#create (log in)" do
    before do
      post "/sso/login", params: params
    end

    context "without valid params" do
      let(:params) { {} }

      it_behaves_like "a forbidden endpoint"
    end

    context "with an outdated timestamp" do
      let(:timestamp) { (Time.current - 10.minutes).to_i.to_s }

      it_behaves_like "a forbidden endpoint"
    end

    context "with an invalid token" do
      let(:resource_token) { Digest::SHA1.hexdigest "forbid:this:request" }

      it_behaves_like "a forbidden endpoint"
    end

    context "with valid params" do
      it "redirects to the dashboard page" do
        expect(response).to redirect_to(dashboard_path)
      end

      it "stores the scoped resource_id into the session" do
        expect(request.session[:resource_id]).to eq(resource.id)
      end
    end
  end

  describe "#destroy (log out)" do
    context "when there's no active session" do
      before do
        delete "/sso/logout", params: nil
      end

      it_behaves_like "a forbidden endpoint"
    end

    context "when there's an active session" do
      before do
        post "/sso/login", params: params
        delete "/sso/logout", params: nil
      end

      it "renders the logged out page" do
        expect(response).to render_template(:destroy)
      end

      it "clears the scoped resource_id from the session" do
        expect(request.session[:resource_id]).to be_nil
      end
    end
  end
end
