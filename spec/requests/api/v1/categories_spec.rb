require "rails_helper"

RSpec.describe "Api::V1::Categories", type: :request do
  let(:user) { create(:user) }

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

  describe "GET /api/v1/categories" do
    it "returns categories as JSON" do
      get "/api/v1/categories"

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json; charset=utf-8")

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("categories")
      expect(json_response["categories"]).to be_an(Array)
      expect(json_response["categories"].first).to have_key("id")
      expect(json_response["categories"].first).to have_key("name")
    end

    it "includes expected categories" do
      get "/api/v1/categories"

      json_response = JSON.parse(response.body)
      category_ids = json_response["categories"].map { |c| c["id"] }

      expect(category_ids).to include("educational", "entertainment", "motivational")
    end
  end
end
