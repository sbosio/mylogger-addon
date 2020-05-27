# frozen_string_literal: true

require "rails_helper"

describe LogFramesController, type: :request do
  let(:content_type) { "application/logplex-1" }
  let(:headers) do
    {
      "CONTENT-TYPE" => content_type,
      "LOGPLEX-DRAIN-TOKEN" => drain_token,
      "LOGPLEX-MSG-COUNT" => message_count,
      "LOGPLEX-FRAME-ID" => external_id
    }
  end
  let(:log_frames_manager_result) { true }
  let(:message_count) { Random.rand(1..5) }

  before do
    allow(LogFramesManager).to receive(:call).and_return(log_frames_manager_result)
    public_send method.to_s, endpoint, params: body, headers: headers
  end

  describe "#create" do
    let(:endpoint) { "/log_frames" }
    let(:external_id) { FFaker::Guid.guid.downcase }
    let(:method) { "post" }
    let(:body) { build(:log_frame, message_count: message_count).frame_content }

    context "when the request doesn't have the correct 'Content-Type' header" do
      let(:headers) { {"CONTENT-TYPE" => "application/json"} }
      let(:body) { {}.to_json }

      it "returns an unprocessable entity status code" do
        expect(response.status).to eq(415)
      end
    end

    context "when the request doesn't have the required Logplex headers" do
      let(:headers) { {"CONTENT-TYPE" => "application/logplex-1"} }

      it "returns an unprocessable entity status code" do
        expect(response).to be_unprocessable
      end
    end

    context "when the request has the correct headers" do
      context "when the drain token doesn't corresponds to any resource" do
        let(:drain_token) { "d.#{FFaker::Guid.guid.downcase}" }

        it "returns an unprocessable entity status code" do
          expect(response).to be_unprocessable
        end
      end

      context "when the drain token corresponds to a resource that isn't active" do
        let(:resource) { create :resource, :with_tokens, state: "deprovisioned" }
        let(:drain_token) { resource.log_drain_token }

        it "returns an unprocessable entity status code" do
          expect(response).to be_unprocessable
        end
      end

      context "when the drain token corresponds to a valid & active resource" do
        let(:resource) { create :resource, :with_tokens, state: "provisioned" }
        let(:drain_token) { resource.log_drain_token }

        it "calls LogFramesManager service" do
          expect(LogFramesManager).to have_received(:call)
        end

        context "when the LogFramesManager service fails" do
          let(:log_frames_manager_result) { false }

          it "returns an unprocessable entity status code" do
            expect(response).to be_unprocessable
          end
        end

        context "when the LogFramesManager service succeeds" do
          it "returns a created status code" do
            expect(response).to be_created
          end
        end
      end
    end
  end
end
