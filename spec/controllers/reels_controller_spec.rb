require "rails_helper"

RSpec.describe ReelsController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET #scene_based" do
    it "builds a new reel with scenes" do
      get :scene_based

      expect(response).to have_http_status(:success)
      expect(assigns(:reel)).to be_a_new(Reel)
      expect(assigns(:reel).mode).to eq('scene_based')
      expect(assigns(:reel).reel_scenes.size).to eq(3)
    end
  end

  describe "POST #create_scene_based" do
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
        post :create_scene_based, params: valid_params
      }.to change(Reel, :count).by(1)

      expect(response).to redirect_to(Reel.last)
      expect(flash[:notice]).to be_present
    end

    it "creates reel scenes" do
      post :create_scene_based, params: valid_params

      reel = Reel.last
      expect(reel.reel_scenes.count).to eq(3)
      expect(reel.mode).to eq('scene_based')
    end
  end

  describe "GET #narrative" do
    it "builds a new narrative reel" do
      get :narrative

      expect(response).to have_http_status(:success)
      expect(assigns(:reel)).to be_a_new(Reel)
      expect(assigns(:reel).mode).to eq('narrative')
    end
  end

  describe "POST #create_narrative" do
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
        post :create_narrative, params: valid_params
      }.to change(Reel, :count).by(1)

      expect(response).to redirect_to(Reel.last)
      expect(flash[:notice]).to be_present
    end

    it "sets correct mode and attributes" do
      post :create_narrative, params: valid_params

      reel = Reel.last
      expect(reel.mode).to eq('narrative')
      expect(reel.title).to eq('Narrative Reel')
      expect(reel.category).to eq('educational')
    end
  end
end
