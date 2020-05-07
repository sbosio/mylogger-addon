# frozen_string_literal: true

require 'rails_helper'

describe Heroku::ProvisioningJob, type: :job do
  let(:resource) { create :resource }

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
    let(:resource_provisioner_result) { true }

    before do
      allow(Heroku::ProvisioningManager::ResourceProvisioner).to(
        receive(:call).with(resource).and_return(resource_provisioner_result)
      )
    end

    it 'calls resource provisioner service object' do
      described_class.perform_now resource.id
      expect(Heroku::ProvisioningManager::ResourceProvisioner).to have_received(:call)
    end

    context 'when resource provisioner service fails' do
      let(:resource_provisioner_result) { false }

      it 'raises an exception' do
        expect {
          described_class.perform_now(resource.id)
        }.to raise_error(Heroku::ProvisioningError)
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
