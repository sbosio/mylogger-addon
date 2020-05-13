# frozen_string_literal: true

require 'rails_helper'

describe Heroku::DeprovisioningJob, type: :job do
  let(:resource) { create :resource, :with_tokens, state: 'provisioned' }

  describe '#perform_later' do
    before do
      ActiveJob::Base.queue_adapter = :test
    end

    it 'enqueues a job' do
      expect {
        described_class.perform_later resource.id
      }.to have_enqueued_job
    end
  end

  describe '#perform' do
    let(:resource_deprovisioner_result) { true }

    before do
      allow(Heroku::ProvisioningManager::ResourceDeprovisioner).to(
        receive(:call).with(resource).and_return(resource_deprovisioner_result)
      )
    end

    it 'calls resource deprovisioner service object' do
      described_class.perform_now resource.id
      expect(Heroku::ProvisioningManager::ResourceDeprovisioner).to have_received(:call)
    end

    context 'when resource deprovisioner service fails' do
      let(:resource_deprovisioner_result) { false }

      it 'raises an exception' do
        expect {
          described_class.perform_now(resource.id)
        }.to raise_error(Heroku::DeprovisioningError)
      end
    end

    context 'when resource provisioner service succeeds' do
      it "doesn't raises an exception" do
        expect {
          described_class.perform_now(resource.id)
        }.not_to raise_error
      end
    end
  end
end
