require "rails_helper"

RSpec.describe "Api::V1::Formats", type: :request do
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

  describe "GET /api/v1/formats" do
    it "returns formats as JSON" do
      get "/api/v1/formats"

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json; charset=utf-8")

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("formats")
      expect(json_response["formats"]).to be_an(Array)
      expect(json_response["formats"].first).to have_key("id")
      expect(json_response["formats"].first).to have_key("name")
      expect(json_response["formats"].first).to have_key("description")
    end

    it "includes expected formats" do
      get "/api/v1/formats"

      json_response = JSON.parse(response.body)
      format_ids = json_response["formats"].map { |f| f["id"] }

      expect(format_ids).to include("short_vertical", "square", "horizontal", "story")
    end
  end
end
