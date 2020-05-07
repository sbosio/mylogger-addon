# frozen_string_literal: true

require 'rails_helper'

describe Heroku::ProvisioningManager::ResourceAllocator, type: :service do
  describe '#call' do
    let(:result) { described_class.call(resource) }
    let(:resource) { create :resource, :with_tokens, state: 'provisioning' }

    it 'returns true' do
      expect(result).to be(true)
    end
  end
end
