require 'rails_helper'

RSpec.describe "Reel Form Submission Integration", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe "Scene-based reel form flow" do
    # This integration test specifically covers the bug that was fixed

    context "GET /reels/scene-based (form load)" do
      it "returns success and renders form" do
        get scene_based_reels_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Scene-Based")
        expect(response.body).to include("form")
      end

      it "does not create any database records" do
        expect {
          get scene_based_reels_path
          get scene_based_reels_path # Multiple requests
        }.not_to change(Reel, :count)
      end

      it "form has correct action and method attributes" do
        get scene_based_reels_path

        # Parse the form to check its attributes
        doc = Nokogiri::HTML(response.body)
        form = doc.css("form").first

        expect(form["method"]).to eq("post")
        expect(form["action"]).to match(%r{/reels/scene-based$|/en/reels$})

        # Should NOT have hidden _method field for PATCH
        method_input = doc.css("input[name='_method']").first
        expect(method_input).to be_nil
      end
    end

    context "POST /reels/scene-based (form submission)" do
      let(:valid_params) do
        {
          reel: {
            template: "only_avatars",
            title: "Integration Test Reel",
            description: "Testing form submission",
            reel_scenes_attributes: {
              "0" => {
                scene_number: 1,
                avatar_id: "avatar_123",
                voice_id: "voice_456",
                script: "Scene 1 script",
                video_type: "avatar"
              },
              "1" => {
                scene_number: 2,
                avatar_id: "avatar_123",
                voice_id: "voice_456",
                script: "Scene 2 script",
                video_type: "avatar"
              },
              "2" => {
                scene_number: 3,
                avatar_id: "avatar_123",
                voice_id: "voice_456",
                script: "Scene 3 script",
                video_type: "avatar"
              }
            }
          }
        }
      end

      it "successfully creates reel and redirects" do
        expect {
          post scene_based_reels_path, params: valid_params
        }.to change(Reel, :count).by(1)

        expect(response).to have_http_status(:redirect)
        expect(response.location).to match(%r{/reels/[a-f0-9-]+$})

        # Verify created reel
        reel = Reel.last
        expect(reel.title).to eq("Integration Test Reel")
        expect(reel.template).to eq("only_avatars")
        expect(reel.reel_scenes.count).to eq(3)
      end

      it "handles route correctly - no 404 or routing errors" do
        post scene_based_reels_path, params: valid_params

        # The bug caused this to return 404 (No route matches [PATCH])
        expect(response).not_to have_http_status(:not_found)
        expect(response).not_to have_http_status(:method_not_allowed)
      end
    end

    context "Incorrect HTTP methods (regression prevention)" do
      let(:basic_params) { { reel: { template: "only_avatars", title: "Test" } } }

      it "PATCH request fails with 404 (as expected)" do
        # This is what the bug was causing - PATCH to non-existent route
        patch "/en/reels/some-uuid", params: basic_params
        expect(response).to have_http_status(:not_found)
      end

      it "PUT request also fails (not supported)" do
        put "/en/reels/some-uuid", params: basic_params
        expect(response).to have_http_status(:not_found)
      end

      it "POST to scene-based path works (correct behavior)" do
        post scene_based_reels_path, params: basic_params

        expect(response).to have_http_status(:redirect)
        expect(Reel.count).to eq(1)
      end
    end
  end

  describe "Smart planning integration" do
    let(:smart_planning_data) do
      {
        title: "Smart Planning Integration Test",
        description: "Testing preload functionality",
        shotplan: {
          scenes: [
            { voiceover: "Preloaded script 1", avatar_id: "smart_avatar", voice_id: "smart_voice" },
            { voiceover: "Preloaded script 2" }
          ]
        }
      }.to_json
    end

    it "GET with smart_planning_data preloads form but doesn't save" do
      expect {
        get scene_based_reels_path, params: { smart_planning_data: smart_planning_data }
      }.not_to change(Reel, :count)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Smart Planning Integration Test")
    end

    it "POST with preloaded data creates reel successfully" do
      # First load form with smart planning data
      get scene_based_reels_path, params: { smart_planning_data: smart_planning_data }

      # Then simulate form submission with that data
      post scene_based_reels_path, params: {
        reel: {
          template: "only_avatars",
          title: "Smart Planning Integration Test",
          description: "Testing preload functionality",
          reel_scenes_attributes: {
            "0" => { scene_number: 1, script: "Preloaded script 1", avatar_id: "smart_avatar", voice_id: "smart_voice", video_type: "avatar" },
            "1" => { scene_number: 2, script: "Preloaded script 2", avatar_id: "default_avatar", voice_id: "default_voice", video_type: "avatar" }
          }
        }
      }

      expect(response).to have_http_status(:redirect)

      reel = Reel.last
      expect(reel.title).to eq("Smart Planning Integration Test")
      expect(reel.reel_scenes.count).to eq(2)
      expect(reel.reel_scenes.ordered.first.script).to eq("Preloaded script 1")
    end
  end

  describe "Error handling" do
    it "invalid template returns error" do
      post scene_based_reels_path, params: {
        reel: { template: "invalid_template", title: "Test" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.content_type).to include('application/json')
      expect(JSON.parse(response.body)).to have_key('error')
      expect(Reel.count).to eq(0)
    end

    it "missing required params handles gracefully" do
      post scene_based_reels_path, params: { reel: {} }

      # Should not crash, should handle gracefully
      expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:redirect).or have_http_status(:bad_request)
    end
  end

  describe "Route constraints verification" do
    # These tests verify the routes are set up correctly

    it "GET /reels/scene-based maps to reels#new with template constraint" do
      get scene_based_reels_path

      expect(controller.controller_name).to eq("reels")
      expect(controller.action_name).to eq("new")
      expect(controller.params[:template]).to eq("only_avatars")
    end

    it "POST /reels/scene-based maps to reels#create with template constraint" do
      post scene_based_reels_path, params: {
        reel: { template: "only_avatars", title: "Route Test" }
      }

      expect(controller.controller_name).to eq("reels")
      expect(controller.action_name).to eq("create")
    end

    it "both routes exist and work correctly" do
      # This test would fail if routes were misconfigured
      expect { get scene_based_reels_path }.not_to raise_error
      expect { post scene_based_reels_path, params: { reel: { template: "only_avatars" } } }.not_to raise_error
    end
  end
end
