require "rails_helper"

RSpec.describe ReelsController, type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET /en/reels/scene-based" do
    it "builds a new reel with scenes" do
      get "/en/reels/scene-based"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Generate Scene-Based Reel")
    end
  end

  describe "POST /en/reels/scene-based" do
    let(:valid_params) do
      {
        reel: {
          title: "Test Reel",
          description: "Test Description",
          use_ai_avatar: true,
          reel_scenes_attributes: {
            "1" => {
              scene_number: 1,
              avatar_id: "avatar_001",
              voice_id: "voice_001",
              script: "Test script 1"
            },
            "2" => {
              scene_number: 2,
              avatar_id: "avatar_002",
              voice_id: "voice_002",
              script: "Test script 2"
            },
            "3" => {
              scene_number: 3,
              avatar_id: "avatar_003",
              voice_id: "voice_003",
              script: "Test script 3"
            }
          }
        }
      }
    end

    it "creates a new scene-based reel" do
      expect {
        post "/en/reels/scene-based", params: valid_params
      }.to change(Reel, :count).by(1)

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(Reel.last)
    end

    it "creates reel scenes" do
      post "/en/reels/scene-based", params: valid_params

      reel = Reel.last
      expect(reel.reel_scenes.count).to eq(3)
      expect(reel.mode).to eq('scene_based')
    end
  end

  describe "GET /en/reels/narrative" do
    it "builds a new narrative reel" do
      get "/en/reels/narrative"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("narrative reel")
    end
  end

  describe "POST /en/reels/narrative" do
    let(:valid_params) do
      {
        reel: {
          title: "Narrative Reel",
          description: "Story description",
          category: "educational",
          format: "short_vertical",
          story_content: "This is my story...",
          music_preference: "upbeat",
          style_preference: "modern"
        }
      }
    end

    it "creates a new narrative reel" do
      expect {
        post "/en/reels/narrative", params: valid_params
      }.to change(Reel, :count).by(1)

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(Reel.last)
    end

    it "sets correct mode and attributes" do
      post "/en/reels/narrative", params: valid_params

      reel = Reel.last
      expect(reel.mode).to eq('narrative')
      expect(reel.title).to eq('Narrative Reel')
      expect(reel.category).to eq('educational')
    end
  end
end
