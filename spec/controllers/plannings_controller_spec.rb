require 'rails_helper'

RSpec.describe PlanningsController, type: :controller do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET #show" do
    context "when user has an existing strategy for current month" do
      let(:current_month) { Date.current.strftime("%Y-%-m") }
      let!(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               month: current_month,
               strategy_name: "Test Strategy",
               objective_of_the_month: "Test Objective")
      end

      it "loads the existing strategy" do
        get :show, params: {}
        expect(response).to have_http_status(:success)
        expect(assigns(:current_plan)).to eq(strategy_plan)
        expect(assigns(:brand)).to eq(brand)
        expect(assigns(:current_month)).to eq(current_month)
      end
    end
  end

  describe "private methods" do
    before { brand }

    it "finds strategy for month correctly" do
      strategy = create(:creas_strategy_plan, user: user, brand: brand, month: "2024-8")

      controller.instance_variable_set(:@brand, brand)
      found_strategy = controller.send(:find_strategy_for_month, "2024-8")

      expect(found_strategy).to eq(strategy)
    end

    it "handles month normalization" do
      strategy = create(:creas_strategy_plan, user: user, brand: brand, month: "2024-08")

      controller.instance_variable_set(:@brand, brand)
      found_strategy = controller.send(:find_strategy_for_month, "2024-8")

      expect(found_strategy).to eq(strategy)
    end
  end
end
