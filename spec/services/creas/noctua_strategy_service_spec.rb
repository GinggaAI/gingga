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

  subject { described_class.new(user: user, brief: brief, brand: brand, month: month) }

  describe '#call' do
    let(:mock_chat_client) { instance_double(GinggaOpenAI::ChatClient) }

    before do
      allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
      allow(mock_chat_client).to receive(:chat!).and_return(mock_openai_response)
    end

    it 'creates a new strategy plan' do
      expect {
        subject.call
      }.to change(CreasStrategyPlan, :count).by(1)
    end

    it 'returns the created strategy plan' do
      plan = subject.call
      expect(plan).to be_a(CreasStrategyPlan)
      expect(plan.user).to eq(user)
      expect(plan.brand).to eq(brand)
      expect(plan.month).to eq(month)
      expect(plan.objective_of_the_month).to eq("awareness")
      expect(plan.frequency_per_week).to eq(4)
    end

    it 'stores the raw payload from OpenAI' do
      plan = subject.call
      expect(plan.raw_payload).to include(
        "brand_name" => brand.name,
        "month" => month,
        "objective_of_the_month" => "awareness"
      )
    end

    it 'creates a brand snapshot' do
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

    it 'stores meta information' do
      plan = subject.call
      expect(plan.meta).to include(
        "model" => "gpt-4o-mini",
        "prompt_version" => "noctua-v1"
      )
    end

    context 'when OpenAI returns non-JSON' do
      before do
        allow(mock_chat_client).to receive(:chat!).and_return("This is not JSON")
      end

      it 'raises a JSON parse error' do
        expect {
          subject.call
        }.to raise_error("Model returned non-JSON content")
      end
    end

    context 'when required fields are missing' do
      let(:invalid_response) do
        {
          "brand_name" => brand.name
          # missing required fields
        }.to_json
      end

      before do
        allow(mock_chat_client).to receive(:chat!).and_return(invalid_response)
      end

      it 'raises an error due to missing required fields' do
        expect {
          subject.call
        }.to raise_error(KeyError, /key not found/)
      end
    end
  end
end
