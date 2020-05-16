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
  let(:message_count) { Random.rand(1..5) }

  before do
    public_send method.to_s, endpoint, params: body, headers: headers
  end

  describe "#create" do
    let(:endpoint) { "/log_frames" }
    let(:external_id) { FFaker::Guid.guid.downcase }
    let(:method) { "post" }
    let(:body) do
      logframe = build :log_frame, message_count: message_count
      logframe.frame_content
    end

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
        let(:external_id) { FFaker::Guid.guid.downcase }

        it "returns an unprocessable entity status code" do
          expect(response).to be_unprocessable
        end
      end

      context "when the drain token corresponds to a resource that isn't active" do
        let(:resource) { create :resource, :with_tokens, state: "deprovisioned" }
        let(:drain_token) { resource.log_drain_token }
        let(:external_id) { FFaker::Guid.guid.downcase }

        it "returns an unprocessable entity status code" do
          expect(response).to be_unprocessable
        end
      end

      context "when the drain token corresponds to a valid & active resource" do
        let(:resource) { create :resource, :with_tokens, state: "provisioned" }
        let(:drain_token) { resource.log_drain_token }
        let(:external_id) { FFaker::Guid.guid.downcase }

        context "when the request payload is valid" do
          it "returns a created status code" do
            expect(response).to be_created
          end

          it "creates a log frame record for the targeted resource" do
            expect(resource.log_frames.count).to eq(1)
          end
        end

        context "when the request payload is invalid" do
          let(:body) { FFaker::Lorem.sentences(Random.rand(1..5)).join("\n") }

          it "returns an unprocessable entity status code" do
            expect(response).to be_unprocessable
          end

          it "doesn't creates a log frame record for the targeted resource" do
            expect(resource.log_frames.count).to be_zero
          end
        end

        context "when the log messages have an incorrect format" do
          let(:body) do
            logframe = build :log_frame, :with_invalid_format, message_count: message_count
            logframe.frame_content
          end

          it "returns an unprocessable entity status code" do
            expect(response).to be_unprocessable
          end

          it "doesn't creates a log frame record for the targeted resource" do
            expect(resource.log_frames.count).to be_zero
          end
        end
      end
    end
  end
end
