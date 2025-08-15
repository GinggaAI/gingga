require 'rails_helper'

RSpec.describe "Smart Planning Integration", type: :request do
  let!(:user) { create(:user) }
  let!(:brand) { create(:brand, user: user) }

  let(:mock_openai_response) do
    {
      "brand_name" => brand.name,
      "brand_slug" => brand.slug,
      "strategy_name" => "Test Strategy",
      "month" => "2024-01",
      "objective_of_the_month" => "Increase brand awareness",
      "frequency_per_week" => 3,
      "content_distribution" => {},
      "weekly_plan" => [
        {
          "week" => 1,
          "theme" => "Awareness",
          "posts" => [
            { "type" => "Post", "day" => "Monday" },
            { "type" => "Reel", "day" => "Wednesday" }
          ]
        }
      ],
      "remix_duet_plan" => {},
      "publish_windows_local" => {},
      "monthly_themes" => [ "Brand awareness" ]
    }.to_json
  end

  def login_user
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password123'
      }
    }
  end

  before do
    # Authenticate user manually for request specs
    login_user

    # Mock OpenAI service
    mock_chat_client = instance_double(GinggaOpenAI::ChatClient)
    allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
    allow(mock_chat_client).to receive(:chat!).and_return(mock_openai_response)
  end

  describe "Planning Page" do
    it "displays the planning interface" do
      get planning_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Smart Planning")
      expect(response.body).to include("Gingga")
      expect(response.body).to include("flex h-screen")
    end
  end

  describe "Content Plan Generation Flow" do
    it "creates plan and redirects with plan_id" do
      expect {
        post creas_strategist_index_path, params: { month: "2024-01" }
      }.to change(CreasStrategyPlan, :count).by(1)

      expect(response).to have_http_status(:see_other)
      expect(response.location).to include("planning?plan_id=")

      # Extract plan_id from redirect URL
      plan_id = response.location.match(/plan_id=([^&]+)/)[1]
      created_plan = CreasStrategyPlan.find(plan_id)

      expect(created_plan.user).to eq(user)
      expect(created_plan.brand).to eq(brand)
      expect(created_plan.month).to eq("2024-01")
    end

    it "handles missing brand gracefully" do
      allow(user).to receive(:brands).and_return(Brand.none)

      post creas_strategist_index_path, params: { month: "2024-01" }

      expect(response).to redirect_to(/\/planning/)
      follow_redirect!
      expect(response.body).to include("My Brand")
    end
  end

  describe "Plan Retrieval" do
    let!(:strategy_plan) { create(:creas_strategy_plan, user: user, brand: brand) }

    it "returns plan data as JSON" do
      get creas_strategy_plan_path(strategy_plan.id)

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response).to include(
        "id" => strategy_plan.id,
        "strategy_name" => strategy_plan.strategy_name,
        "weeks" => be_an(Array)
      )
    end

    it "returns 404 for non-existent plan" do
      get creas_strategy_plan_path(999999)
      expect(response).to have_http_status(:not_found)
    end
  end
end
