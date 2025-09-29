# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Planning::ContentRefinementsController, type: :controller do
  include Devise::Test::ControllerHelpers
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user, slug: 'test-brand', name: 'Test Brand') }
  let(:strategy_plan) do
    create(:creas_strategy_plan,
           user: user,
           brand: brand,
           month: '2025-01',
           status: 'completed',
           weekly_plan: sample_weekly_plan)
  end

  let(:sample_weekly_plan) do
    [
      {
        "week" => 1,
        "ideas" => [
          {
            "id" => "202501-test-brand-w1-i1-C",
            "title" => "Sample Content Week 1",
            "description" => "Sample description for week 1",
            "platform" => "Instagram",
            "status" => "draft"
          }
        ]
      },
      {
        "week" => 2,
        "ideas" => [
          {
            "id" => "202501-test-brand-w2-i1-R",
            "title" => "Sample Content Week 2",
            "description" => "Sample description for week 2",
            "platform" => "TikTok",
            "status" => "draft"
          }
        ]
      }
    ]
  end

  before do
    sign_in user
    allow(user).to receive(:current_brand).and_return(brand)
    allow(Planning::BrandResolver).to receive(:call).with(user).and_return(brand)
    allow(Planning::StrategyResolver).to receive(:new).and_return(double(call: strategy_plan))
  end

  describe 'POST #create' do
    context 'full strategy refinement' do
      let(:params) { { plan_id: strategy_plan.id } }

      it 'calls ContentRefinementService with correct parameters' do
        service_double = double('ContentRefinementService')
        result_double = double('ServiceResult', success?: true, success_message: 'Content refinement started')

        expect(Planning::ContentRefinementService).to receive(:new)
          .with(strategy: strategy_plan, target_week: nil, user: user)
          .and_return(service_double)
        expect(service_double).to receive(:call).and_return(result_double)

        post :create, params: params

        expect(response).to redirect_to(planning_path(plan_id: strategy_plan.id))
        expect(flash[:notice]).to eq('Content refinement started')
      end

      it 'uses brand context through BrandResolver' do
        service_double = double('ContentRefinementService', call: double(success?: true, success_message: 'Success'))
        allow(Planning::ContentRefinementService).to receive(:new).and_return(service_double)

        expect(Planning::BrandResolver).to receive(:call).with(user).and_return(brand)

        post :create, params: params
      end

      it 'uses StrategyResolver to find strategy with brand context' do
        service_double = double('ContentRefinementService', call: double(success?: true, success_message: 'Success'))
        allow(Planning::ContentRefinementService).to receive(:new).and_return(service_double)

        expect(Planning::StrategyResolver).to receive(:new)
          .with(brand: brand, month: nil, plan_id: strategy_plan.id.to_s)
          .and_return(double(call: strategy_plan))

        post :create, params: params
      end

      context 'when service fails' do
        it 'redirects with error message' do
          service_double = double('ContentRefinementService')
          result_double = double('ServiceResult', success?: false, error_message: 'Refinement failed')

          allow(Planning::ContentRefinementService).to receive(:new).and_return(service_double)
          allow(service_double).to receive(:call).and_return(result_double)

          post :create, params: params

          expect(response).to redirect_to(planning_path(plan_id: strategy_plan.id))
          expect(flash[:alert]).to eq('Refinement failed')
        end
      end
    end

    context 'week-specific refinement' do
      let(:params) { { plan_id: strategy_plan.id, week_number: 2 } }

      it 'calls ContentRefinementService with target week' do
        service_double = double('ContentRefinementService')
        result_double = double('ServiceResult', success?: true, success_message: 'Week 2 refinement started')

        expect(Planning::ContentRefinementService).to receive(:new)
          .with(strategy: strategy_plan, target_week: 2, user: user)
          .and_return(service_double)
        expect(service_double).to receive(:call).and_return(result_double)

        post :create, params: params

        expect(response).to redirect_to(planning_path(plan_id: strategy_plan.id))
        expect(flash[:notice]).to eq('Week 2 refinement started')
      end
    end

    context 'when strategy not found' do
      before do
        allow(Planning::StrategyResolver).to receive(:new).and_return(double(call: nil))
      end

      it 'redirects with error message' do
        post :create, params: { plan_id: 'nonexistent' }

        expect(response).to redirect_to(planning_path)
        expect(flash[:alert]).to eq('No strategy found to refine.')
      end
    end

    context 'when exception occurs' do
      it 'handles unexpected errors gracefully' do
        allow(Planning::ContentRefinementService).to receive(:new).and_raise(StandardError.new('Unexpected error'))

        post :create, params: { plan_id: strategy_plan.id }

        expect(response).to redirect_to(planning_path(plan_id: strategy_plan.id))
        expect(flash[:alert]).to include('Failed to refine content')
      end
    end
  end

  describe 'Brand isolation' do
    let(:other_user) { create(:user) }
    let(:other_brand) { create(:brand, user: other_user, slug: 'other-brand') }
    let(:other_strategy) do
      create(:creas_strategy_plan,
             user: other_user,
             brand: other_brand,
             month: '2025-01',
             status: 'completed')
    end

    it 'does not allow refining strategies from other brands' do
      # Try to refine strategy from another brand
      allow(Planning::StrategyResolver).to receive(:new).and_return(double(call: nil))

      post :create, params: { plan_id: other_strategy.id }

      expect(response).to redirect_to(planning_path)
      expect(flash[:alert]).to eq('No strategy found to refine.')
    end

    it 'ensures BrandResolver uses current user' do
      service_double = double('ContentRefinementService', call: double(success?: true, success_message: 'Success'))
      allow(Planning::ContentRefinementService).to receive(:new).and_return(service_double)

      expect(Planning::BrandResolver).to receive(:call).with(user).and_return(brand)

      post :create, params: { plan_id: strategy_plan.id }
    end
  end

  describe 'private methods' do
    let(:controller_instance) { described_class.new }

    before do
      allow(controller_instance).to receive(:current_user).and_return(user)
      allow(controller_instance).to receive(:params).and_return(ActionController::Parameters.new(params))
    end

    describe '#determine_target_week' do
      context 'with week_number parameter' do
        let(:params) { { week_number: '3' } }

        it 'returns week number as integer' do
          allow(controller_instance).to receive(:action_name).and_return('create')
          result = controller_instance.send(:determine_target_week)
          expect(result).to eq(3)
        end
      end

      context 'without week_number parameter' do
        let(:params) { { plan_id: strategy_plan.id } }

        it 'returns nil for full strategy refinement' do
          allow(controller_instance).to receive(:action_name).and_return('create')
          result = controller_instance.send(:determine_target_week)
          expect(result).to be_nil
        end
      end
    end
  end

  describe 'authentication' do
    before { sign_out user }

    it 'requires user authentication' do
      post :create, params: { plan_id: strategy_plan.id }
      expect(response).to have_http_status(:redirect) # Redirect to login
    end
  end
end