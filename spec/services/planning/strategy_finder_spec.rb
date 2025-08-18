require 'rails_helper'

RSpec.describe Planning::StrategyFinder do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  describe '.find_for_brand_and_month' do
    context 'when brand is nil' do
      it 'returns nil' do
        result = described_class.find_for_brand_and_month(nil, "2024-8")
        expect(result).to be_nil
      end
    end

    context 'when brand is not persisted' do
      let(:brand) { build(:brand, user: user) }

      it 'returns nil' do
        result = described_class.find_for_brand_and_month(brand, "2024-8")
        expect(result).to be_nil
      end
    end

    context 'with exact month match' do
      let!(:strategy) { create(:creas_strategy_plan, user: user, brand: brand, month: "2024-8") }

      it 'finds strategy by exact match' do
        result = described_class.find_for_brand_and_month(brand, "2024-8")
        expect(result).to eq(strategy)
      end
    end

    context 'with normalized month match' do
      let!(:strategy) { create(:creas_strategy_plan, user: user, brand: brand, month: "2024-08") }

      it 'finds strategy by normalized match when searching for single digit' do
        result = described_class.find_for_brand_and_month(brand, "2024-8")
        expect(result).to eq(strategy)
      end

      it 'finds strategy by normalized match when searching for zero-padded' do
        strategy.update!(month: "2024-8")
        result = described_class.find_for_brand_and_month(brand, "2024-08")
        expect(result).to eq(strategy)
      end
    end

    context 'with multiple strategies' do
      let!(:older_strategy) { create(:creas_strategy_plan, user: user, brand: brand, month: "2024-8", created_at: 2.days.ago) }
      let!(:newer_strategy) { create(:creas_strategy_plan, user: user, brand: brand, month: "2024-8", created_at: 1.day.ago) }

      it 'returns the most recent strategy' do
        result = described_class.find_for_brand_and_month(brand, "2024-8")
        expect(result).to eq(newer_strategy)
      end
    end

    context 'when no strategy exists' do
      it 'returns nil' do
        result = described_class.find_for_brand_and_month(brand, "2024-8")
        expect(result).to be_nil
      end
    end

    context 'with strategies for other brands' do
      let(:other_user) { create(:user) }
      let(:other_brand) { create(:brand, user: other_user) }
      let!(:other_strategy) { create(:creas_strategy_plan, user: other_user, brand: other_brand, month: "2024-8") }

      it 'does not return strategies from other brands' do
        result = described_class.find_for_brand_and_month(brand, "2024-8")
        expect(result).to be_nil
      end
    end
  end
end
