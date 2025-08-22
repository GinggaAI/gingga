require 'rails_helper'

RSpec.describe PlanningsController, type: :controller do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET #show" do
    context "when user has no brand" do
      before { brand.destroy }

      it "handles missing brand gracefully" do
        get :show
        expect(response).to have_http_status(:success)
        expect(assigns(:brand)).to be_nil
        expect(assigns(:plans)).to be_present
      end
    end

    context "when user has an existing strategy" do
      let!(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               month: Date.current.strftime("%Y-%-m"),
               weekly_plan: [
                 {
                   "week" => 1,
                   "publish_cadence" => 3,
                   "ideas" => [
                     {
                       "id" => "test-id",
                       "status" => "draft",
                       "title" => "Test Content",
                       "pilar" => "C"
                     }
                   ]
                 }
               ])
      end

      it "loads the existing strategy and builds real plans" do
        get :show, params: {}

        expect(response).to have_http_status(:success)
        expect(assigns(:current_strategy)).to eq(strategy_plan)
        expect(assigns(:brand)).to eq(brand)
        expect(assigns(:plans)).to be_present
        expect(assigns(:plans).size).to eq(1)
        expect(assigns(:plans).first[:week_number]).to eq(1)
        expect(assigns(:plans).first[:content_count]).to eq(1)
      end
    end

    context "with specific plan_id" do
      let!(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               month: "2024-08")
      end

      it "loads specific strategy by ID" do
        get :show, params: { plan_id: strategy_plan.id }

        expect(response).to have_http_status(:success)
        expect(assigns(:current_strategy)).to eq(strategy_plan)
        expect(assigns(:current_month)).to eq("2024-08")
      end
    end
  end

  describe "GET #smart_planning" do
    context "when no strategy exists" do
      it "builds weekly plans" do
        # For this test, we just verify the method exists and doesn't crash
        # The detailed logic is tested in the service specs
        controller_instance = described_class.new
        controller_instance.instance_variable_set(:@current_strategy, nil)
        plans = controller_instance.send(:build_weekly_plans)

        expect(plans).to be_present
        expect(plans.first[:status]).to eq(:needs_strategy)
      end
    end
  end

  describe "GET #strategy_for_month" do
    context "when strategy exists for month" do
      let!(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               month: "2024-08",
               strategy_name: "August Strategy")
      end

      it "returns formatted strategy as JSON" do
        get :strategy_for_month, params: { month: "2024-08" }, format: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['strategy_name']).to eq("August Strategy")
        expect(json_response['month']).to eq("2024-08")
      end
    end

    context "when no strategy exists" do
      it "returns not found error" do
        get :strategy_for_month, params: { month: "2024-08" }, format: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to be_present
      end
    end
  end

  describe "private method behavior verification" do
    it "uses service objects for complex logic" do
      # This test verifies that the controller delegates to service objects
      # rather than implementing complex logic internally

      expect(Planning::WeeklyPlansBuilder).to receive(:call).and_call_original

      get :show, params: {}

      expect(response).to have_http_status(:success)
    end
  end
end
