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
        plan = create(:creas_strategy_plan,
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

        # Create content items using the service (simulating what happens after Noctua completion)
        Creas::ContentItemInitializerService.new(strategy_plan: plan).call
        plan
      end

      it 'displays the strategy plan via presenter' do
        get planning_path

        expect(response).to have_http_status(:success)

        # Should display month via presenter
        expect(response.body).to include(Date.current.strftime("%B %Y"))

        # Should include plan data via presenter currentPlan JSON
        expect(response.body).to include('"strategy_name":"Test Strategy"')
        expect(response.body).to include('"objective_of_the_month":"Test Objective"')
        expect(response.body).to include('"Test Content (Week 1)"')

        # Should not contain null for currentPlan
        expect(response.body).not_to include('window.currentPlan = null;')
      end

      it 'includes all plan data needed for JavaScript' do
        get planning_path

        json_match = response.body.match(/window\.currentPlan = ({.*?});/m)
        expect(json_match).to be_present

        plan_json = JSON.parse(json_match[1])
        expect(plan_json['strategy_name']).to eq('Test Strategy')
        expect(plan_json['objective_of_the_month']).to eq('Test Objective')
        expect(plan_json['weekly_plan']).to be_present
      end
    end

    context 'when user has no strategy for current month' do
      it 'displays safe defaults via presenter' do
        get planning_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(Date.current.strftime("%B %Y"))
        expect(response.body).to include('window.currentPlan = null;')
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
        expect(response.body).to include('"strategy_name":"December Strategy"')
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
        expect(response.body).to include('"strategy_name":"August Strategy"')
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
      expect(response.body).to include("window.currentPlan = null;")
    end
  end
end
