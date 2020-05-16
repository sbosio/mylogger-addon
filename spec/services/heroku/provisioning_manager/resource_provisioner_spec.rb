# frozen_string_literal: true

require "rails_helper"

describe Heroku::ProvisioningManager::ResourceProvisioner, type: :service do
  describe "#call" do
    let(:result) { described_class.call(resource) }
    let(:resource) { create :resource, state: "provisioning" }

    before do
      allow(Heroku::AuthorizationManager::GrantExchanger).to(
        receive(:call).with(resource).and_return(grant_exchanger_result)
      )
      allow(Heroku::ProvisioningManager::ResourceAllocator).to(
        receive(:call).with(resource).and_return(resource_allocator_result)
      )
      allow(Heroku::ProvisioningManager::AddonConfigUpdater).to(
        receive(:call).with(resource).and_return(addon_config_updater_result)
      )
    end

    context "when the grant exchanger service fails" do
      let(:grant_exchanger_result) { false }
      let(:resource_allocator_result) { nil }
      let(:addon_config_updater_result) { nil }

      it "calls grant exchanger service object" do
        result
        expect(Heroku::AuthorizationManager::GrantExchanger).to have_received(:call).with(resource)
      end

      it "never calls resource allocator service object" do
        result
        expect(Heroku::ProvisioningManager::ResourceAllocator).not_to have_received(:call).with(resource)
      end

      it "never calls addon config updater service object" do
        result
        expect(Heroku::ProvisioningManager::AddonConfigUpdater).not_to have_received(:call).with(resource)
      end

      it "returns false" do
        expect(result).to be(false)
      end
    end

    context "when grant exchanger service succeeds and resource allocator service fails" do
      let(:grant_exchanger_result) { true }
      let(:resource_allocator_result) { false }
      let(:addon_config_updater_result) { nil }

      it "calls resource allocator service object" do
        result
        expect(Heroku::ProvisioningManager::ResourceAllocator).to have_received(:call).with(resource)
      end

      it "never calls addon config updater service object" do
        result
        expect(Heroku::ProvisioningManager::AddonConfigUpdater).not_to have_received(:call).with(resource)
      end

      it "returns false" do
        expect(result).to be(false)
      end
    end

    context "when resource allocator service succeeds and addon config updater service fails" do
      let(:grant_exchanger_result) { true }
      let(:resource_allocator_result) { true }
      let(:addon_config_updater_result) { false }

      it "calls addon config updater service object" do
        result
        expect(Heroku::ProvisioningManager::AddonConfigUpdater).to have_received(:call).with(resource)
      end

      it "returns false" do
        expect(result).to be(false)
      end
    end

    context "when all orchestrated services succeed" do
      let(:grant_exchanger_result) { true }
      let(:resource_allocator_result) { true }
      let(:addon_config_updater_result) { true }

      it "sets resource's state to 'provisioned'" do
        result
        expect(resource.provisioned?).to be(true)
      end

      it "returns true" do
        expect(result).to be(true)
      end
    end

    context "when any exception is raised" do
      let(:grant_exchanger_result) { true }
      let(:resource_allocator_result) { true }
      let(:addon_config_updater_result) { true }

      it "returns false" do
        allow(resource).to receive(:provision_completed!).and_raise(StateMachines::InvalidTransition)
        expect(result).to be(false)
      end
    end
  end
end
