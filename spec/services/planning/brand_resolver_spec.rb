require 'rails_helper'

RSpec.describe Planning::BrandResolver do
  describe '.call' do
    let(:user) { create(:user) }
    let(:brand) { create(:brand, user: user) }

    it 'returns the first brand for the user' do
      result = described_class.call(user)
      expect(result).to eq(brand)
    end

    context 'when user has no brands' do
      let(:user) { create(:user) }

      it 'returns nil' do
        result = described_class.call(user)
        expect(result).to be_nil
      end
    end
  end
end
