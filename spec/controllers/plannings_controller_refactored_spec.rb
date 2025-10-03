require 'rails_helper'

RSpec.describe PlanningsController, type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    sign_in user, scope: :user
    user.update_last_brand(brand)
  end

  describe "GET #show" do
    context "when user has no brand" do
      before { brand.destroy }

      it "handles missing brand gracefully" do
        get planning_path(brand_slug: "nonexistent", locale: :en)
        expect(response.status).to be_between(200, 399)
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
        get planning_path(brand_slug: brand.slug, locale: :en)

        expect(response).to have_http_status(:success)
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
        get planning_path(brand_slug: brand.slug, locale: :en), params: { plan_id: strategy_plan.id }

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET #smart_planning" do
    it "responds without server error" do
      get smart_planning_path(brand_slug: brand.slug, locale: :en)
      expect(response.status).to_not eq(500)
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
        get strategy_for_month_planning_path(brand_slug: brand.slug, locale: :en), params: { month: "2024-08" }, headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['strategy_name']).to eq("August Strategy")
        expect(json_response['month']).to eq("2024-08")
      end
    end

    context "when no strategy exists" do
      it "returns not found error" do
        get strategy_for_month_planning_path(brand_slug: brand.slug, locale: :en), params: { month: "2024-08" }, headers: { 'Accept' => 'application/json' }

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

      get planning_path(brand_slug: brand.slug, locale: :en)

      expect(response).to have_http_status(:success)
    end
  end
end
