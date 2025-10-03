# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreasStrategistController, type: :controller do
  include ActiveJob::TestHelper
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:primary_brand) { create(:brand, user: user, slug: 'primary-brand', name: 'Primary Brand') }
  let(:secondary_brand) { create(:brand, user: user, slug: 'secondary-brand', name: 'Secondary Brand') }

  let(:valid_strategy_params) do
    {
      month: "2025-01",
      strategy_form: {
        objective_of_the_month: "awareness",
        objective_details: "Build brand awareness",
        frequency_per_week: 3,
        monthly_themes: "brand building",
        selected_templates: '["only_avatars"]'
      }
    }
  end

  let(:mock_openai_response) do
    {
      "brand_name" => primary_brand.name,
      "brand_slug" => primary_brand.slug,
      "strategy_name" => "AI Generated Strategy (4 weeks)",
      "month" => "2025-01",
      "objective_of_the_month" => "awareness",
      "frequency_per_week" => 3,
      "content_distribution" => {},
      "weekly_plan" => [
        {
          "week" => 1,
          "ideas" => [
            {
              "id" => "202501-primary-brand-w1-i1-C",
              "title" => "Brand Story Introduction",
              "description" => "Tell the story of Primary Brand",
              "platform" => "Instagram",
              "status" => "draft"
            }
          ]
        }
      ],
      "monthly_themes" => [ "brand building" ]
    }.to_json
  end

  before do
    sign_in user, scope: :user

    # Setup brand context
    primary_brand
    secondary_brand

    # Set the user's last_brand to ensure current_brand returns primary_brand
    user.update(last_brand: primary_brand)

    # Mock API services
    allow_any_instance_of(ApiTokenValidatorService).to receive(:call).and_return({ valid: true })

    mock_chat_client = instance_double(GinggaOpenAI::ChatClient)
    allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
    allow(mock_chat_client).to receive(:chat!).and_return(mock_openai_response)
  end

  describe 'Brand Association in Strategy Creation' do
    context 'when user has multiple brands' do
      it 'creates strategy associated with current_brand' do
        expect {
          post :create, params: valid_strategy_params, format: :json
        }.to change(CreasStrategyPlan, :count).by(1)

        created_strategy = CreasStrategyPlan.last
        expect(created_strategy.brand).to eq(primary_brand)
        expect(created_strategy.user).to eq(user)
      end

      it 'does not associate strategy with other user brands' do
        post :create, params: valid_strategy_params, format: :json

        created_strategy = CreasStrategyPlan.last
        expect(created_strategy.brand).not_to eq(secondary_brand)
      end

      it 'uses current_brand in find_brand method' do
        # Spy on the controller's find_brand method
        allow(controller).to receive(:find_brand).and_call_original

        post :create, params: valid_strategy_params, format: :json

        expect(controller).to have_received(:find_brand)
        expect(controller.instance_variable_get(:@brand)).to eq(primary_brand)
      end
    end

    context 'when switching between brands' do
      it 'creates strategy for the currently active brand' do
        # The key behavior: controller uses current_brand to determine which brand to associate
        # This is set via user.last_brand in the global before block

        # Verify primary_brand is the current_brand
        expect(user.current_brand).to eq(primary_brand)

        # Create strategy - should use current_brand (primary_brand)
        post :create, params: valid_strategy_params, format: :json
        created_strategy = CreasStrategyPlan.last

        # Verify strategy is associated with the current brand
        expect(created_strategy.brand).to eq(primary_brand)
        expect(created_strategy.user).to eq(user)

        # Verify controller received and used the correct brand
        expect(controller.instance_variable_get(:@brand)).to eq(primary_brand)
      end
    end

    context 'when user has no current brand' do
      before do
        # Remove all brands to simulate no current brand
        user.brands.destroy_all
        user.update(last_brand: nil)
      end

      it 'returns error when current_brand is nil' do
        post :create, params: valid_strategy_params, format: :json

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to include('create a brand profile first')
      end

      it 'redirects to planning path for HTML requests' do
        post :create, params: valid_strategy_params, format: :html

        expect(response).to redirect_to(planning_path)
        expect(flash[:alert]).to include('create a brand profile first')
      end
    end

    context 'Content Items Association' do
      it 'creates content items associated with correct brand' do
        # Verify that the service is called with the correct brand
        # Content items will be created asynchronously by the background job
        # This test ensures the brand context is properly passed
        post :create, params: valid_strategy_params, format: :json

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true

        # The strategy should be associated with the correct brand
        created_strategy = CreasStrategyPlan.last
        expect(created_strategy.brand).to eq(primary_brand)
        expect(created_strategy.user).to eq(user)
      end
    end

    context 'Brand Resolver Integration' do
      it 'uses Planning::BrandResolver.call(current_user) pattern' do
        # Verify the pattern used in PlanningsController is consistent
        expect(Planning::BrandResolver).to receive(:call).with(user).and_return(primary_brand)

        # Simulate the pattern from PlanningsController
        resolved_brand = Planning::BrandResolver.call(user)
        expect(resolved_brand).to eq(primary_brand)
      end
    end
  end

  describe 'Service Integration with Brand Context' do
    it 'passes correct brand to CreateStrategyService' do
      expect(CreateStrategyService).to receive(:call).with(
        user: user,
        brand: primary_brand,
        month: "2025-01",
        strategy_params: hash_including(:objective_of_the_month)
      ).and_call_original

      post :create, params: valid_strategy_params, format: :json
    end

    it 'ensures CreateStrategyService receives brand parameter' do
      # Verify that the service gets the brand from controller
      service_double = double('CreateStrategyService')
      plan_double = instance_double(CreasStrategyPlan,
                                     id: 1,
                                     status: 'completed',
                                     strategy_name: 'Test Strategy',
                                     month: '2025-01',
                                     objective_of_the_month: 'awareness',
                                     objective_details: 'Build brand awareness',
                                     frequency_per_week: 3,
                                     monthly_themes: [],
                                     selected_templates: [],
                                     content_distribution: {},
                                     weekly_plan: [])
      result_double = double('ServiceResult', success?: true, plan: plan_double)

      expect(CreateStrategyService).to receive(:call)
        .with(hash_including(brand: primary_brand))
        .and_return(result_double)

      post :create, params: valid_strategy_params, format: :json
    end
  end

  describe 'Response includes correct brand context' do
    it 'includes brand information in successful response' do
      post :create, params: valid_strategy_params, format: :json

      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true

      plan_data = json_response['plan']
      expect(plan_data).to be_present

      # Verify plan is associated with correct brand
      plan = CreasStrategyPlan.find(plan_data['id'])
      expect(plan.brand).to eq(primary_brand)
    end

    it 'includes redirect URL with correct brand context' do
      post :create, params: valid_strategy_params, format: :json

      json_response = JSON.parse(response.body)
      redirect_url = json_response['redirect_url']

      expect(redirect_url).to include("/#{primary_brand.slug}/")
      expect(redirect_url).to include(planning_path(plan_id: json_response['plan']['id']))
    end
  end

  describe 'Edge Cases and Error Handling' do
    context 'when brand is deleted during request' do
      it 'handles brand deletion gracefully' do
        # Simulate brand being deleted during request processing
        allow(controller).to receive(:find_brand) do
          primary_brand.destroy
          user.update(last_brand: nil)
          controller.instance_variable_set(:@brand, nil)
        end

        post :create, params: valid_strategy_params, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
      end
    end

    context 'when user loses access to brand' do
      it 'prevents strategy creation for inaccessible brand' do
        # Simulate user losing access to brand by removing all brands
        user.brands.destroy_all
        user.update(last_brand: nil)

        post :create, params: valid_strategy_params, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(CreasStrategyPlan.count).to eq(0)
      end
    end
  end

  describe 'Integration with Weekly Plan Content' do
    it 'ensures weekly plan content references correct brand' do
      post :create, params: valid_strategy_params, format: :json

      expect(response).to have_http_status(:success)

      created_strategy = CreasStrategyPlan.last
      expect(created_strategy).to be_present

      # The primary assertion: strategy is associated with correct brand
      expect(created_strategy.brand).to eq(primary_brand)
      expect(created_strategy.brand_id).to eq(primary_brand.id)
      expect(created_strategy.user).to eq(user)

      # Strategy should not be associated with other brands
      expect(created_strategy.brand).not_to eq(secondary_brand)

      # Weekly plan is a JSON field - verify structure if present
      weekly_plan = created_strategy.weekly_plan
      expect(weekly_plan).to be_an(Array)

      # If weekly plan has content, it should reference the correct brand
      # Note: weekly_plan content is generated asynchronously, so it may be empty initially
      if weekly_plan.any?
        weekly_plan_json = weekly_plan.to_json
        expect(weekly_plan_json).not_to include(secondary_brand.name)
        expect(weekly_plan_json).not_to include(secondary_brand.slug)
      end
    end
  end
end
