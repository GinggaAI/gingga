require 'rails_helper'
require Rails.root.join('app/services/gingga_openai/chat_client')

RSpec.describe CreasStrategistController, type: :request do
  include ActiveJob::TestHelper

  let!(:user) { create(:user) }
  let!(:brand) { create(:brand, user: user) }

  let(:valid_params) do
    {
      month: "2025-08",
      strategy_form: {
        objective_of_the_month: "awareness",
        frequency_per_week: 4,
        monthly_themes: "product launch",
        resources_override: '{"ai_avatars": true}'
      }
    }
  end

  let(:mock_openai_response) do
    {
      "brand_name" => brand.name,
      "brand_slug" => brand.slug,
      "strategy_name" => "August 2025 Strategy",
      "month" => "2025-08",
      "objective_of_the_month" => "awareness",
      "frequency_per_week" => 4,
      "content_distribution" => {},
      "weekly_plan" => [],
      "remix_duet_plan" => {},
      "publish_windows_local" => {},
      "monthly_themes" => [ "product launch" ]
    }.to_json
  end

  before do
    # Mock API token validator to avoid real API calls
    allow_any_instance_of(ApiTokenValidatorService).to receive(:call).and_return({ valid: true })

    # Mock current_user to return our test user
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)

    # Mock OpenAI service
    mock_chat_client = instance_double(GinggaOpenAI::ChatClient)
    allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
    allow(mock_chat_client).to receive(:chat!).and_return(mock_openai_response)
  end

  describe 'POST /creas_strategist' do
    context 'with valid parameters' do
      it 'creates a strategy plan and returns JSON response' do
        expect {
          post '/creas_strategist', params: valid_params, headers: { 'Accept' => 'application/json' }
        }.to change(CreasStrategyPlan, :count).by(1)

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true

        # Since jobs run inline, reload the plan to get the updated data
        plan_id = json_response["plan"]["id"]
        completed_plan = CreasStrategyPlan.find(plan_id)

        expect(completed_plan).to have_attributes(
          month: "2025-08",
          objective_of_the_month: "awareness",
          frequency_per_week: 4,
          status: "completed"
        )
      end
    end

    context 'with optional parameters' do
      it 'uses default when objective_of_the_month is missing' do
        invalid_params = valid_params.dup
        invalid_params[:strategy_form].delete(:objective_of_the_month)
        post '/creas_strategist', params: invalid_params, headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('success')
        expect(json_response['success']).to be true
      end

      it 'uses current month when month is missing' do
        post '/creas_strategist', params: valid_params.except(:month), headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('success')
        expect(json_response['success']).to be true
      end
    end

    context 'when user has no brand' do
      before { brand.destroy }

      it 'returns 422' do
        post '/creas_strategist', params: valid_params, headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
      end
    end

    context 'when OpenAI service fails' do
      before do
        allow_any_instance_of(Creas::NoctuaStrategyService).to receive(:call).and_raise("OpenAI API Error")
      end

      it 'returns 422 with error message' do
        post '/creas_strategist', params: valid_params, headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response).to include('error' => 'OpenAI API Error')
      end
    end
  end
end
