require 'rails_helper'

RSpec.describe GenerateNoctuaStrategyJob, type: :job do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:strategy_plan) { create(:creas_strategy_plan, user: user, brand: brand, status: :pending) }
  let(:brief) do
    {
      brand_info: 'Test brand',
      objective: 'Test objective',
      frequency: 3
    }
  end

  let(:mock_ai_response) do
    {
      'strategy_name' => 'Test Strategy',
      'objective_of_the_month' => 'Increase brand awareness',
      'frequency_per_week' => 3,
      'monthly_themes' => [ 'Brand awareness', 'Product showcase' ],
      'resources_override' => {},
      'content_distribution' => { 'instagram' => 70, 'tiktok' => 30 },
      'weekly_plan' => [],
      'remix_duet_plan' => {},
      'publish_windows_local' => {}
    }.to_json
  end

  describe '#perform' do
    subject { described_class.new }

    before do
      # Mock the OpenAI chat client
      allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(
        double(chat!: mock_ai_response)
      )
    end

    context 'when strategy generation succeeds' do
      it 'updates strategy plan status to processing then completed' do
        subject.perform(strategy_plan.id, brief)

        strategy_plan.reload
        expect(strategy_plan.completed?).to be true
        expect(strategy_plan.strategy_name).to eq('Test Strategy')
        expect(strategy_plan.objective_of_the_month).to eq('Increase brand awareness')
      end

      it 'calls the OpenAI chat client' do
        chat_client_double = double(chat!: mock_ai_response)
        expect(GinggaOpenAI::ChatClient).to receive(:new)
          .with(
            user: strategy_plan.user,
            model: "gpt-4o",
            temperature: 0.4
          )
          .and_return(chat_client_double)

        expect(chat_client_double).to receive(:chat!)

        subject.perform(strategy_plan.id, brief)
      end
    end

    context 'when strategy generation fails' do
      let(:error_message) { 'OpenAI API error' }

      before do
        # Override the mock to raise an error
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
