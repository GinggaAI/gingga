require 'rails_helper'

RSpec.describe GenerateNoctuaStrategyJob, type: :job do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:strategy_plan) { create(:creas_strategy_plan, user: user, brand: brand, status: :pending) }
  let(:brief) do
    {
      brand_name: 'EcoGlow Beauty',
      industry: 'Skincare & Beauty',
      audience_profile: 'Women aged 25-45, environmentally conscious, middle to high income, active on social media',
      content_language: 'en-US',
      account_language: 'en-US',
      target_region: 'North America',
      timezone: 'EST',
      value_proposition: 'Natural, effective skincare that protects your skin and the planet',
      main_offer: 'Eco-friendly skincare products with natural ingredients',
      mission: 'To provide clean beauty solutions that are good for you and the environment',
      tone_style: 'Authentic, educational, and inspiring',
      priority_platforms: [ 'Instagram', 'TikTok' ],
      monthly_themes: [ 'Natural ingredients education', 'Sustainability awareness' ],
      objective_of_the_month: 'awareness',
      available_resources: 'AI avatars, stock footage, editing tools',
      frequency_per_week: 3,
      guardrails: 'No medical claims, focus on natural benefits',
      preferred_ctas: 'Shop now, Learn more, Discover natural beauty'
    }
  end

  describe '#perform' do
    subject { described_class.new }

    context 'when strategy generation succeeds', vcr: { cassette_name: 'noctua_strategy_success' } do
      it 'updates strategy plan status to processing then completed' do
        subject.perform(strategy_plan.id, brief)

        strategy_plan.reload
        expect(strategy_plan.completed?).to be true
        expect(strategy_plan.strategy_name).to be_present
        expect(strategy_plan.objective_of_the_month).to be_present
        expect(strategy_plan.frequency_per_week).to eq(3)
        expect(strategy_plan.raw_payload).to be_present
      end

      it 'creates an AiResponse record' do
        expect {
          subject.perform(strategy_plan.id, brief)
        }.to change(AiResponse, :count).by(1)

        ai_response = AiResponse.last
        expect(ai_response.user).to eq(strategy_plan.user)
        expect(ai_response.service_name).to eq('noctua')
        expect(ai_response.ai_model).to eq('gpt-4o')
        expect(ai_response.prompt_version).to eq('noctua-v1')
        expect(ai_response.raw_request).to have_key('system')
        expect(ai_response.raw_request).to have_key('user')
        expect(ai_response.raw_response).to be_present
      end

      it 'validates and processes the weekly distribution' do
        subject.perform(strategy_plan.id, brief)

        strategy_plan.reload
        expect(strategy_plan.weekly_plan).to be_present
        expect(strategy_plan.content_distribution).to be_present
      end
    end

    context 'when strategy generation fails' do
      let(:error_message) { 'OpenAI API error' }

      before do
        # Mock the OpenAI chat client to raise an error
        chat_client_double = double
        allow(chat_client_double).to receive(:chat!).and_raise(StandardError.new(error_message))
        allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(chat_client_double)
      end

      it 'updates strategy plan status to failed with error message' do
        subject.perform(strategy_plan.id, brief)

        strategy_plan.reload
        expect(strategy_plan.failed?).to be true
        expect(strategy_plan.error_message).to eq(error_message)
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)
        expect(Rails.logger).to receive(:error).with("Strategy plan #{strategy_plan.id} failed: #{error_message}")

        subject.perform(strategy_plan.id, brief)
      end
    end

    context 'when JSON parsing fails', vcr: { cassette_name: 'noctua_strategy_invalid_json' } do
      before do
        # Mock the client to return invalid JSON
        chat_client_double = double(chat!: 'Invalid JSON response')
        allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(chat_client_double)
      end

      it 'updates strategy plan status to failed with JSON parse error' do
        subject.perform(strategy_plan.id, brief)

        strategy_plan.reload
        expect(strategy_plan.failed?).to be true
        expect(strategy_plan.error_message).to include('Model returned non-JSON content')
      end
    end

    context 'when OpenAI returns incomplete brief error', vcr: { cassette_name: 'noctua_incomplete_brief_error' } do
      let(:incomplete_brief) do
        {
          brand_info: 'Test brand'  # Only minimal info
        }
      end

      it 'updates strategy plan status to failed with incomplete brief error' do
        subject.perform(strategy_plan.id, incomplete_brief)

        strategy_plan.reload
        expect(strategy_plan.failed?).to be true
        expect(strategy_plan.error_message).to include('brief')
        expect(strategy_plan.meta['error_type']).to eq('incomplete_brief')
      end
    end

    context 'when strategy plan is not found' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          subject.perform(999999, brief)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'job queue' do
    it 'is queued on the default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end
  end
end
