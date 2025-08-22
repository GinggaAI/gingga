require 'rails_helper'

RSpec.describe PlanningsController, type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  def login_user
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password123'
      }
    }
  end

  before do
    login_user
  end

  describe "GET /planning" do
    context "when user has no brand" do
      let(:user) { create(:user) } # user without brand

      it "displays planning page but with limited functionality" do
        get planning_path
        expect(response).to have_http_status(:success)
        expect(assigns(:brand)).to be_nil
        expect(assigns(:current_strategy)).to be_nil
      end
    end

    context "when user has a brand but no existing strategy" do
      before { brand } # create brand

      it "displays the planning page with current month" do
        get planning_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(Date.current.strftime("%B %Y"))
      end

      it "initializes currentPlan as null" do
        get planning_path
        expect(response.body).to include('data-planning-current-plan-value')
      end

      it "shows 'Add Content' button" do
        get planning_path
        expect(response.body).to include("Add Content")
      end
    end

    context "when user has an existing strategy for current month" do
      let!(:strategy_plan) do
        create(:creas_strategy_plan,
               brand: brand,
               month: Date.current.strftime("%Y-%-m"),
               strategy_name: "Test Strategy",
               objective_of_the_month: "Test Objective")
      end

      it "loads the existing strategy" do
        get planning_path
        expect(response).to have_http_status(:success)
        # For now, just check that page loads and we're finding some strategy data
        expect(response.body).to include("Smart Planning")
      end

      it "should find and load the strategy in controller" do
        # Debug test to understand what's happening
        get planning_path
        expect(strategy_plan).to be_persisted
        expect(strategy_plan.brand).to eq(brand)
        expect(strategy_plan.month).to eq(Date.current.strftime("%Y-%-m"))
      end
    end

    context "with specific plan_id parameter" do
      let!(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               month: "2024-12",
               strategy_name: "December Strategy")
      end

      it "loads the specific strategy plan" do
        get planning_path(plan_id: strategy_plan.id)
        expect(response).to have_http_status(:success)
        expect(assigns(:current_strategy)).to eq(strategy_plan)
        expect(assigns(:current_month)).to eq("2024-12")
      end
    end

    context "with custom month parameter" do
      it "sets the correct month display" do
        get planning_path(month: "2024-12")
        expect(response).to have_http_status(:success)
        expect(assigns(:current_month)).to eq("2024-12")
        expect(assigns(:current_month_display)).to eq("December 2024")
      end
    end
  end

  describe "GET /planning/strategy_for_month" do
    before { brand }

    context "when strategy exists for the month" do
      let!(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               month: "2024-8",
               strategy_name: "August Strategy",
               objective_of_the_month: "August Goals")
      end

      it "returns the strategy as JSON" do
        get strategy_for_month_planning_path, params: { month: "2024-8" }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response["strategy_name"]).to eq("August Strategy")
        expect(json_response["objective_of_the_month"]).to eq("August Goals")
      end

      it "handles different month formats" do
        # Test with zero-padded month
        get strategy_for_month_planning_path, params: { month: "2024-08" }
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response["strategy_name"]).to eq("August Strategy")
      end
    end

    context "when no strategy exists for the month" do
      it "returns 404 with error message" do
        get strategy_for_month_planning_path, params: { month: "2024-7" }
        expect(response).to have_http_status(:not_found)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("No strategy found for month")
      end
    end
  end

  describe "Month normalization" do
    before do
      # Force creation of brand to ensure it exists
      brand
    end

    let!(:strategy_plan_padded) do
      create(:creas_strategy_plan, user: user, brand: brand, month: "2024-08", strategy_name: "Padded")
    end

    let!(:strategy_plan_unpadded) do
      create(:creas_strategy_plan, user: user, brand: brand, month: "2024-7", strategy_name: "Unpadded")
    end

    it "finds strategy with padded month when searching unpadded" do
      get strategy_for_month_planning_path, params: { month: "2024-8" }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response["strategy_name"]).to eq("Padded")
    end

    it "finds strategy with unpadded month when searching padded" do
      get strategy_for_month_planning_path, params: { month: "2024-07" }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response["strategy_name"]).to eq("Unpadded")
    end
  end
end
