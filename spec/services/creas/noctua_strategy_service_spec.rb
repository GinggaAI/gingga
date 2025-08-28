require 'rails_helper'
require Rails.root.join('app/services/gingga_openai/chat_client')

RSpec.describe Creas::NoctuaStrategyService do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let!(:audience) { create(:audience, brand: brand) }
  let!(:product) { create(:product, brand: brand) }
  let!(:brand_channel) { create(:brand_channel, brand: brand) }

  let(:brief) do
    {
      brand_name: brand.name,
      brand_slug: brand.slug,
      industry: brand.industry,
      objective_of_the_month: "awareness",
      frequency_per_week: 4
    }
  end

  let(:month) { "2025-08" }

  let(:mock_openai_response) do
    {
      "brand_name" => brand.name,
      "brand_slug" => brand.slug,
      "strategy_name" => "August 2025 Strategy",
      "month" => month,
      "objective_of_the_month" => "awareness",
      "frequency_per_week" => 4,
      "content_distribution" => { "C" => { "goal" => "Growth" } },
      "weekly_plan" => [ { "week" => 1, "ideas" => [] } ],
      "remix_duet_plan" => { "rationale" => "Test" },
      "publish_windows_local" => {},
      "monthly_themes" => [ "test" ]
    }.to_json
  end

  subject { described_class.new(user: user, brief: brief, brand: brand, month: month, strategy_form: strategy_form) }
  let(:strategy_form) { {} }

  describe '#call (async version)' do
    before do
      # Mock the background job to prevent it from being enqueued in tests
      allow(GenerateNoctuaStrategyJob).to receive(:perform_later)
    end

    it 'creates a new strategy plan with pending status' do
      expect {
        subject.call
      }.to change(CreasStrategyPlan, :count).by(1)
    end

    it 'returns the created strategy plan with pending status' do
      plan = subject.call
      expect(plan).to be_a(CreasStrategyPlan)
      expect(plan.user).to eq(user)
      expect(plan.brand).to eq(brand)
      expect(plan.month).to eq(month)
      expect(plan.pending?).to be true
      expect(plan.objective_of_the_month).to be_nil # Not filled yet
      expect(plan.frequency_per_week).to be_nil # Not filled yet
    end

    it 'creates a brand snapshot immediately' do
      plan = subject.call
      expect(plan.brand_snapshot).to include(
        "name" => brand.name,
        "slug" => brand.slug,
        "industry" => brand.industry
      )
      expect(plan.brand_snapshot["audiences"]).to be_an(Array)
      expect(plan.brand_snapshot["products"]).to be_an(Array)
      expect(plan.brand_snapshot["channels"]).to be_an(Array)
    end

    it 'queues a batch job for processing' do
      expect(GenerateNoctuaStrategyBatchJob).to receive(:perform_later).with(
        instance_of(String), # strategy_plan.id
        brief,
        1,                   # batch_number
        4,                   # total_batches
        instance_of(String)  # batch_id
      )

      subject.call
    end

    context 'with strategy_form provided' do
      let(:strategy_form) do
        {
          objective_of_the_month: 'sales',
          primary_objective: 'awareness',
          frequency_per_week: 5,
          monthly_themes: [ 'theme1', 'theme2' ],
          resources_override: { ai_avatars: true, stock: false }
        }
      end

      it 'sets strategy form attributes on the plan' do
        plan = subject.call

        expect(plan.objective_of_the_month).to eq('sales') # Uses objective_of_the_month first
        expect(plan.frequency_per_week).to eq(5)
        expect(plan.monthly_themes).to eq([ 'theme1', 'theme2' ])
        expect(plan.resources_override).to eq({ 'ai_avatars' => true, 'stock' => false })
      end

      context 'when objective_of_the_month is nil but primary_objective is present' do
        let(:strategy_form) do
          {
            primary_objective: 'engagement',
            frequency_per_week: 3
          }
        end

        it 'falls back to primary_objective' do
          plan = subject.call
          expect(plan.objective_of_the_month).to eq('engagement')
        end
      end
    end
  end
end
