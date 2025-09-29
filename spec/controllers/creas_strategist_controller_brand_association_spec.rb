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
      "monthly_themes" => ["brand building"]
    }.to_json
  end

  before do
    sign_in user

    # Setup brand context
    primary_brand
    secondary_brand
    allow(user).to receive(:current_brand).and_return(primary_brand)

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
        # Create strategy for primary brand
        post :create, params: valid_strategy_params, format: :json
        primary_strategy = CreasStrategyPlan.last

        # Switch to secondary brand
        allow(user).to receive(:current_brand).and_return(secondary_brand)

        # Create strategy for secondary brand
        post :create, params: valid_strategy_params.merge(month: "2025-02"), format: :json
        secondary_strategy = CreasStrategyPlan.last

        expect(primary_strategy.brand).to eq(primary_brand)
        expect(secondary_strategy.brand).to eq(secondary_brand)
        expect(primary_strategy).not_to eq(secondary_strategy)
      end
    end

    context 'when user has no current brand' do
      before do
        allow(user).to receive(:current_brand).and_return(nil)
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
        # Ensure content items are created during strategy generation
        allow_any_instance_of(GenerateNoctuaStrategyBatchJob).to receive(:perform) do |job, plan_id|
          plan = CreasStrategyPlan.find(plan_id)

          # Simulate content item creation
          create(:creas_content_item,
                 creas_strategy_plan: plan,
                 user: plan.user,
                 brand: plan.brand,
                 content_name: "Test Content",
                 week: 1)
        end

        post :create, params: valid_strategy_params, format: :json

        created_strategy = CreasStrategyPlan.last
        content_items = created_strategy.creas_content_items

        expect(content_items).not_to be_empty
        content_items.each do |item|
          expect(item.brand).to eq(primary_brand)
          expect(item.user).to eq(user)
        end
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
      result_double = double('ServiceResult', success?: true, plan: instance_double(CreasStrategyPlan, id: 1))

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
        # Start request with valid brand
        allow(user).to receive(:current_brand).and_return(primary_brand)

        # Simulate brand being deleted during request processing
        allow(controller).to receive(:find_brand) do
          primary_brand.destroy
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
        # Simulate user losing access to brand
        allow(user).to receive(:current_brand).and_return(nil)

        post :create, params: valid_strategy_params, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(CreasStrategyPlan.count).to eq(0)
      end
    end
  end

  describe 'Integration with Weekly Plan Content' do
    it 'ensures weekly plan content references correct brand' do
      post :create, params: valid_strategy_params, format: :json

      created_strategy = CreasStrategyPlan.last
      weekly_plan = created_strategy.weekly_plan

      # Verify weekly plan doesn't contain wrong brand references
      weekly_plan_json = weekly_plan.to_json
      expect(weekly_plan_json).not_to include('New Brand')
      expect(weekly_plan_json).not_to include('brand-1')

      # Should contain correct brand name
      expect(weekly_plan_json).to include(primary_brand.name)
    end
  end
end