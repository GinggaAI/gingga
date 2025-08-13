require 'rails_helper'
require Rails.root.join('app/services/gingga_openai/chat_client')

RSpec.describe CreasStrategistController, type: :request do
  let!(:user) { create(:user) }
  let!(:brand) { create(:brand, user: user) }

  let(:valid_params) do
    {
      brand_id: brand.id,
      month: "2025-08",
      objective_of_the_month: "awareness",
      frequency_per_week: 4,
      monthly_themes: [ "product launch" ],
      resources_override: { ai_avatars: true }
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
      it 'creates a strategy plan and returns 201' do
        expect {
          post '/creas_strategist', params: valid_params
        }.to change(CreasStrategyPlan, :count).by(1)

        expect(response).to have_http_status(:created)

        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          "month" => "2025-08",
          "objective_of_the_month" => "awareness",
          "frequency_per_week" => 4
        )
      end
    end

    context 'with missing required parameters' do
      it 'returns 422 when brand_id is missing' do
        post '/creas_strategist', params: valid_params.except(:brand_id)
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
      end

      it 'returns 422 when month is missing' do
        post '/creas_strategist', params: valid_params.except(:month)
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
      end
    end

    context 'when brand does not belong to user' do
      let(:other_user) { create(:user) }
      let(:other_brand) { create(:brand, user: other_user) }

      it 'returns 404' do
        post '/creas_strategist', params: valid_params.merge(brand_id: other_brand.id)
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
      end
    end

    context 'when OpenAI service fails' do
      before do
        allow_any_instance_of(Creas::NoctuaStrategyService).to receive(:call).and_raise("OpenAI API Error")
      end

      it 'returns 422 with error message' do
        post '/creas_strategist', params: valid_params
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response).to include('error' => 'OpenAI API Error')
      end
    end
  end
end
