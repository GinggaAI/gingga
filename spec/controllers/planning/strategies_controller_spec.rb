require 'rails_helper'

RSpec.describe "Planning::StrategiesController", type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    sign_in user, scope: :user
    allow(Planning::BrandResolver).to receive(:call).and_return(brand)
  end

  describe 'GET #for_month' do
    let(:strategy) { create(:creas_strategy_plan, brand: brand) }

    context 'when strategy exists' do
      before do
        allow(Planning::StrategyFinder).to receive(:find_for_brand_and_month)
          .with(brand, '2024-12')
          .and_return(strategy)
        allow(Planning::StrategyFormatter).to receive(:call)
          .with(strategy)
          .and_return({ id: strategy.id })
      end

      it 'returns formatted strategy' do
        get for_month_planning_strategies_path, params: { month: '2024-12' }

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to eq({ 'id' => strategy.id })
      end
    end

    context 'when strategy does not exist' do
      before do
        allow(Planning::StrategyFinder).to receive(:find_for_brand_and_month)
          .with(brand, '2024-12')
          .and_return(nil)
      end

      it 'returns not found error' do
        get for_month_planning_strategies_path, params: { month: '2024-12' }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to have_key('error')
      end
    end
  end
end
