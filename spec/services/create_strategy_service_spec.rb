require 'rails_helper'

RSpec.describe CreateStrategyService do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  describe '#call' do
    context 'with selected_templates' do
      let(:strategy_params) do
        {
          objective_of_the_month: 'awareness',
          objective_details: 'Increase brand awareness for new product',
          frequency_per_week: 4,
          monthly_themes: [ 'innovation', 'technology' ],
          selected_templates: [ 'only_avatars', 'avatar_and_video', 'remix' ]
        }
      end

      it 'creates strategy plan with selected templates' do
        allow_any_instance_of(Creas::NoctuaStrategyService).to receive(:call).and_return(
          instance_double(CreasStrategyPlan, id: 1, selected_templates: [ 'only_avatars', 'avatar_and_video', 'remix' ])
        )

        result = described_class.call(
          user: user,
          brand: brand,
          month: '2025-09',
          strategy_params: strategy_params
        )

        expect(result.success?).to be true
      end
    end

    context 'without selected_templates' do
      let(:strategy_params) do
        {
          objective_of_the_month: 'engagement',
          frequency_per_week: 3,
          monthly_themes: [ 'community' ]
        }
      end

      it 'uses default templates' do
        strategy_plan = double('CreasStrategyPlan', id: 1)
        service_double = double('NoctuaStrategyService')

        expect(Creas::NoctuaStrategyService).to receive(:new) do |args|
          expect(args[:strategy_form][:selected_templates]).to eq([ 'only_avatars' ])
          service_double
        end
        expect(service_double).to receive(:call).and_return(strategy_plan)

        result = described_class.call(
          user: user,
          brand: brand,
          month: '2025-09',
          strategy_params: strategy_params
        )

        expect(result.success?).to be true
      end
    end

    context 'with invalid templates' do
      let(:strategy_params) do
        {
          objective_of_the_month: 'sales',
          frequency_per_week: 3,
          selected_templates: [ 'invalid_template', 'only_avatars' ]
        }
      end

      it 'filters out invalid templates and keeps valid ones' do
        strategy_plan = double('CreasStrategyPlan', id: 1)
        service_double = double('NoctuaStrategyService')

        expect(Creas::NoctuaStrategyService).to receive(:new) do |args|
          expect(args[:strategy_form][:selected_templates]).to eq([ 'only_avatars' ])
          service_double
        end
        expect(service_double).to receive(:call).and_return(strategy_plan)

        result = described_class.call(
          user: user,
          brand: brand,
          month: '2025-09',
          strategy_params: strategy_params
        )

        expect(result.success?).to be true
      end
    end
  end
end
