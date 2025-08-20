require 'rails_helper'

RSpec.describe 'Month Parameter Flow Integration', type: :integration do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let!(:audience) { create(:audience, brand: brand) }
  let!(:product) { create(:product, brand: brand) }
  let!(:brand_channel) { create(:brand_channel, brand: brand) }

  let(:month) { '2025-12' }
  let(:strategy_params) do
    {
      objective_of_the_month: 'awareness',
      frequency_per_week: 3,
      monthly_themes: [ 'holiday season', 'year-end celebration' ]
    }
  end

  let(:mock_openai_response) do
    {
      "brand_name" => brand.name,
      "brand_slug" => brand.slug,
      "strategy_name" => "December 2025 Strategy",
      "month" => "2023-11", # This wrong month should be overridden
      "objective_of_the_month" => "awareness",
      "frequency_per_week" => 3,
      "content_distribution" => { "C" => { "goal" => "Growth" } },
      "weekly_plan" => [ { "week" => 1, "ideas" => [] } ],
      "remix_duet_plan" => { "rationale" => "Test" },
      "publish_windows_local" => {},
      "monthly_themes" => [ "holiday season", "year-end celebration" ]
    }.to_json
  end

  before do
    # Mock OpenAI response
    allow_any_instance_of(GinggaOpenAI::ChatClient).to receive(:chat!).and_return(mock_openai_response)
  end

  describe 'CreateStrategyService flow' do
    it 'preserves the month parameter through the entire flow' do
      # Create strategy using the service
      result = CreateStrategyService.call(
        user: user,
        brand: brand,
        month: month,
        strategy_params: strategy_params
      )

      expect(result.success?).to be true

      # Verify the created strategy has the correct month
      strategy = result.plan
      expect(strategy.month).to eq(month), "Expected month to be #{month}, but got #{strategy.month}"
      expect(strategy.month).not_to eq("2023-11"), "Month should not be the value from OpenAI response"
    end
  end

  describe 'NoctuaBriefAssembler with month' do
    it 'includes month in the brief sent to OpenAI' do
      strategy_form = {
        objective_of_the_month: strategy_params[:objective_of_the_month],
        frequency_per_week: strategy_params[:frequency_per_week],
        monthly_themes: strategy_params[:monthly_themes]
      }

      brief = NoctuaBriefAssembler.call(
        brand: brand,
        strategy_form: strategy_form,
        month: month
      )

      expect(brief[:month]).to eq(month)
    end
  end

  describe 'Direct NoctuaStrategyService call' do
    it 'uses the service month parameter instead of OpenAI response month' do
      brief = {
        brand_name: brand.name,
        month: month, # This should be preserved
        objective_of_the_month: 'awareness',
        frequency_per_week: 3
      }

      strategy = Creas::NoctuaStrategyService.new(
        user: user,
        brief: brief,
        brand: brand,
        month: month
      ).call

      expect(strategy.month).to eq(month)
      expect(strategy.month).not_to eq("2023-11")
    end
  end
end
