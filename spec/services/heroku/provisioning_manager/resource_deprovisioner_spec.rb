# frozen_string_literal: true

require 'rails_helper'

describe Heroku::ProvisioningManager::ResourceDeprovisioner, type: :service do
  describe '#call' do
    let(:resource) { create :resource, :with_tokens, state: resource_state }
    let(:result) { described_class.call(resource) }

    context "when the resource isn't in 'deprovisioning' state" do
      let(:resource_state) { 'provisioned' }

      it 'returns false' do
        expect(result).to be(false)
      end
    end

    context "when the resource is in 'deprovisioning' state" do
      let(:resource_state) { 'deprovisioning' }

      context 'with no exceptions raised' do
        let(:another_resource) { create :resource, :with_tokens, state: 'provisioned' }
        let(:other_log_frames) { create_list(:log_frame, Random.rand(1..5), resource: another_resource) }

        it 'returns true' do
          expect(result).to be(true)
        end

        it "sets resource's state to 'deprovisioned'" do
          result
          expect(resource.deprovisioned?).to be(true)
        end

        it 'removes all log frames associated with the resource' do
          create_list(:log_frame, Random.rand(1..5), resource: resource)
          result
          expect(resource.log_frames.count).to be_zero
        end

        it "doesn't remove any log frame not associated with the resource" do
          create_list(:log_frame, Random.rand(1..5), resource: resource)
          another_resource = create :resource, :with_tokens, state: 'provisioned'
          other_log_frames = create_list(:log_frame, Random.rand(1..5), resource: another_resource)
          result
          expect(another_resource.log_frames.count).to eq(other_log_frames.size)
        end
      end

      context 'with an exception raised' do
        before do
          allow(resource).to receive(:deprovision_completed!).and_raise(StateMachines::InvalidTransition)
        end

        it 'returns false' do
          expect(result).to be(false)
        end

        it "doesn't removes any log frames" do
          log_frames = create_list(:log_frame, Random.rand(1..5), resource: resource)
          result
          expect(resource.log_frames.count).to eq(log_frames.size)
        end
      end
    end
  end
end
