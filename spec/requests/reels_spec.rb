require "rails_helper"

RSpec.describe "Reels", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET /en/reels/scene-based" do
    it "builds a new reel with scenes" do
      get "/en/reels/scene-based"

      expect(response).to have_http_status(:success)
      # In request specs, we can't easily access assigns, so we check for success
      expect(response.body).to include("Scene-Based Reel")
    end
  end

  describe "GET /en/reels/narrative" do
    it "builds a new narrative reel" do
      get "/en/reels/narrative"

      expect(response).to have_http_status(:success)
      # In request specs, we check the response content instead of assigns
      expect(response.body).to include("Narrative")
    end
  end

  describe "POST /reels/create_scene_based" do
    let(:valid_params) do
      {
        reel: {
          title: "Scene-based Reel",
          description: "Test description",
          use_ai_avatar: true,
          additional_instructions: "Test instructions",
          reel_scenes_attributes: {
            "0" => {
              scene_number: 1,
              avatar_id: "avatar_1",
              voice_id: "voice_1",
              script: "Scene 1 script"
            },
            "1" => {
              scene_number: 2,
              avatar_id: "avatar_2",
              voice_id: "voice_2",
              script: "Scene 2 script"
            },
            "2" => {
              scene_number: 3,
              avatar_id: "avatar_3",
              voice_id: "voice_3",
              script: "Scene 3 script"
            }
          }
        }
      }
    end

    it "creates a new scene-based reel" do
      expect {
        post "/en/reels/scene-based", params: valid_params
      }.to change(Reel, :count).by(1)

      expect(response).to redirect_to(Reel.last)
      expect(flash[:notice]).to be_present
    end

    it "creates reel scenes" do
      post "/en/reels/scene-based", params: valid_params

      reel = Reel.last
      expect(reel.reel_scenes.count).to eq(3)
      expect(reel.mode).to eq('scene_based')
      expect(reel.title).to eq("Scene-based Reel")
    end
  end

  describe "POST /reels/create_narrative" do
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

      expect(response).to redirect_to(Reel.last)
      expect(flash[:notice]).to be_present
    end

    it "sets correct mode and attributes" do
      post "/en/reels/narrative", params: valid_params

      reel = Reel.last
      expect(reel.mode).to eq('narrative')
      expect(reel.title).to eq("Narrative Reel")
      expect(reel.category).to eq("educational")
      expect(reel.format).to eq("short_vertical")
    end
  end
end
