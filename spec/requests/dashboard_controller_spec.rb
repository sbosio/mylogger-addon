# frozen_string_literal: true

require "rails_helper"
require "support/shared_examples/session"
require "support/helpers/session_helper"

describe DashboardsController, type: :request do
  include SessionHelper

  describe "#show" do
    context "without an active session" do
      before do
        get "/"
      end

      it_behaves_like "a forbidden endpoint"
    end

    context "with an active session" do
      before do
        sign_in(resource)
        get "/"
      end

      context "with a provisioned resource" do
        let(:resource) { create :resource, :with_tokens, state: "provisioned" }

        it "returns an ok status code" do
          expect(response).to be_ok
        end
      end

      context "with a deprovisioned resource" do
        let(:resource) { create :resource, :with_tokens, state: "deprovisioned" }

        it_behaves_like "a forbidden endpoint"
      end
    end
  end
end
