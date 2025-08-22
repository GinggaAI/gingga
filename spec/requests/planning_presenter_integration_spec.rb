require 'rails_helper'

RSpec.describe 'Planning Presenter Integration', type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password123'
      }
    }
  end

  describe 'Strategy plan display via presenter' do
    context 'when user has existing strategy for current month' do
      let!(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               month: Date.current.strftime("%Y-%-m"),
               strategy_name: "Test Strategy",
               objective_of_the_month: "Test Objective",
               weekly_plan: [
                 {
                   week: 1,
                   ideas: [
                     {
                       id: "202508-test-w1-i1-C",
                       title: "Test Content",
                       hook: "Test hook",
                       pilar: "C"
                     }
                   ]
                 }
               ])
      end

      it 'displays the strategy plan via presenter' do
        get planning_path

        expect(response).to have_http_status(:success)

        # Should display month via presenter
        expect(response.body).to include(Date.current.strftime("%B %Y"))

        # Should include plan data via Stimulus data attributes
        expect(response.body).to include('data-planning-current-plan-value')
        # Check for HTML-encoded JSON in data attributes
        expect(response.body).to include('&quot;strategy_name&quot;:&quot;Test Strategy&quot;')
        expect(response.body).to include('&quot;objective_of_the_month&quot;:&quot;Test Objective&quot;')
        expect(response.body).to include('&quot;Test Content&quot;')

        # Should not contain null for currentPlan in data attribute (means plan exists)
        expect(response.body).not_to include('data-planning-current-plan-value="null"')
      end

      it 'includes all plan data needed for JavaScript' do
        get planning_path

        # Check for Stimulus data attribute containing the plan JSON
        expect(response.body).to include('data-planning-current-plan-value')
        # Look for HTML encoded JSON data in the attribute
        expect(response.body).to include('&quot;strategy_name&quot;:&quot;Test Strategy&quot;')
        expect(response.body).to include('&quot;objective_of_the_month&quot;:&quot;Test Objective&quot;')
        expect(response.body).to include('&quot;weekly_plan&quot;')
      end
    end

    context 'when user has no strategy for current month' do
      it 'displays safe defaults via presenter' do
        get planning_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(Date.current.strftime("%B %Y"))
        expect(response.body).to include("data-planning-current-plan-value='null'")
      end
    end

    context 'with specific plan_id parameter' do
      let!(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               month: "2024-12",
               strategy_name: "December Strategy")
      end

      it 'loads specific plan via presenter' do
        get planning_path(plan_id: strategy_plan.id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('data-planning-current-plan-value')
        expect(response.body).to include('&quot;strategy_name&quot;:&quot;December Strategy&quot;')
      end
    end

    context 'with month parameter' do
      let!(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               month: "2025-08",
               strategy_name: "August Strategy")
      end

      it 'displays correct month and plan' do
        get planning_path(month: "2025-08")

        expect(response).to have_http_status(:success)
        expect(response.body).to include("August 2025")
        expect(response.body).to include('data-planning-current-plan-value')
        expect(response.body).to include('&quot;strategy_name&quot;:&quot;August Strategy&quot;')
      end
    end
  end

  describe 'XSS security with functional plans' do
    let!(:strategy_plan) do
      create(:creas_strategy_plan,
               user: user,
               brand: brand,
               month: Date.current.strftime("%Y-%-m"),
               strategy_name: "Safe Strategy")
    end

    it 'maintains security with existing plans' do
      malicious_month = "2025-08'; alert('xss'); //"
      get planning_path(month: malicious_month)

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("alert('xss')")
      expect(response.body).to include("Invalid Month")
      # Should still show null plan when malicious month fails
      expect(response.body).to include("data-planning-current-plan-value='null'")
    end
  end
end
