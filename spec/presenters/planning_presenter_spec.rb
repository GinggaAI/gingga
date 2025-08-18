require 'rails_helper'

RSpec.describe PlanningPresenter do
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:presenter) { described_class.new(params, brand: brand) }

  describe '#display_month' do
    context 'with valid month parameter' do
      let(:params) { { month: '2025-08' } }

      it 'formats month correctly' do
        expect(presenter.display_month).to eq('August 2025')
      end
    end

    context 'with single digit month' do
      let(:params) { { month: '2025-8' } }

      it 'formats month correctly' do
        expect(presenter.display_month).to eq('August 2025')
      end
    end

    context 'with missing month parameter' do
      let(:params) { {} }

      it 'returns current month' do
        travel_to Date.new(2025, 8, 15) do
          expect(presenter.display_month).to eq('August 2025')
        end
      end
    end

    context 'with malformed month parameter' do
      let(:params) { { month: '<script>alert("xss")</script>' } }

      it 'returns safe fallback' do
        expect(presenter.display_month).to eq('Invalid Month')
      end
    end

    context 'with invalid date format' do
      let(:params) { { month: '2025-13' } }

      it 'returns safe fallback' do
        expect(presenter.display_month).to eq('Invalid Month')
      end
    end
  end

  describe '#safe_month_for_js' do
    context 'with valid month parameter' do
      let(:params) { { month: '2025-08' } }

      it 'returns sanitized month string' do
        expect(presenter.safe_month_for_js).to eq('2025-08')
      end
    end

    context 'with malicious input' do
      let(:params) { { month: "2025-08'; alert('xss'); //" } }

      it 'returns sanitized safe value' do
        expect(presenter.safe_month_for_js).to eq('2025-8') # current fallback
      end
    end

    context 'with missing month' do
      let(:params) { {} }

      it 'returns current month in safe format' do
        travel_to Date.new(2025, 8, 15) do
          expect(presenter.safe_month_for_js).to eq('2025-8')
        end
      end
    end
  end

  describe '#current_plan_json' do
    context 'with existing plan' do
      let!(:plan) { create(:creas_strategy_plan, brand: brand, month: '2025-08') }
      let(:params) { { month: '2025-08' } }

      it 'returns plan as JSON' do
        expect(presenter.current_plan_json).to include(plan.strategy_name)
      end
    end

    context 'without existing plan' do
      let(:params) { { month: '2025-08' } }

      it 'returns null' do
        expect(presenter.current_plan_json).to eq('null')
      end
    end

    context 'with plan_id parameter' do
      let!(:plan) { create(:creas_strategy_plan, brand: brand, month: '2024-12') }
      let(:params) { { plan_id: plan.id } }
      
      it 'returns specific plan by ID' do
        expect(presenter.current_plan_json).to include(plan.strategy_name)
      end
    end

    context 'with missing month parameter (should use current month)' do
      let(:params) { {} }
      
      it 'searches for current month plan' do
        travel_to Date.new(2025, 8, 15) do
          plan = create(:creas_strategy_plan, brand: brand, month: '2025-8')
          result = presenter.current_plan_json
          expect(result).to include(plan.strategy_name)
        end
      end
    end
  end
end
