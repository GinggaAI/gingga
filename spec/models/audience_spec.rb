require 'rails_helper'

RSpec.describe Audience, type: :model do
  describe 'associations' do
    it { should belong_to(:brand) }
  end

  describe 'JSONB defaults' do
    let(:audience) { create(:audience) }

    it 'has default empty hash for demographic_profile' do
      expect(audience.demographic_profile).to be_a(Hash)
    end

    it 'has default empty arrays for interests' do
      expect(audience.interests).to be_an(Array)
    end

    it 'has default empty arrays for digital_behavior' do
      expect(audience.digital_behavior).to be_an(Array)
    end
  end
end
