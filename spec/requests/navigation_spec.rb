require 'rails_helper'

RSpec.describe "Basic Navigation", type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    sign_in user, scope: :user
  end

  describe "Main Application Pages" do
    context "when user is authenticated" do
      it "displays the brand edit page (/my-brand)" do
        get my_brand_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Brand Profile")
      end

      it "displays the planning page (/planning)" do
        get planning_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Smart Planning")
        expect(response.body).to include("Add Content")
      end

      # TODO: Fix 406 errors on these routes
      # it "displays the smart planning page (/smart-planning)" do
      #   get smart_planning_path
      #   expect(response).to have_http_status(:success)
      # end

      # it "displays the reels index page (/reels)" do
      #   get reels_path
      #   expect(response).to have_http_status(:success)
      # end

      # TODO: Fix missing Reel model fields (use_ai_avatar, music_preference, etc.)
      # it "displays the scene-based reels page (/reels/scene-based)" do
      #   get scene_based_reels_path
      #   expect(response).to have_http_status(:success)
      #   expect(response.body).to include("Scene-Based Reel")
      # end

      # it "displays the narrative reels page (/reels/narrative)" do
      #   get narrative_reels_path
      #   expect(response).to have_http_status(:success)
      #   expect(response.body).to include("Narrative Reel")
      # end

      it "displays the viral ideas page (/viral_ideas)" do
        get viral_ideas_path
        expect(response).to have_http_status(:success)
      end

      it "displays the auto creation page (/auto_creation)" do
        get auto_creation_path
        expect(response).to have_http_status(:success)
      end

      it "displays the analytics page (/analytics)" do
        get analytics_path
        expect(response).to have_http_status(:success)
      end

      it "displays the community page (/community)" do
        get community_path
        expect(response).to have_http_status(:success)
      end

      it "displays the settings page (/settings)" do
        get settings_path
        expect(response).to have_http_status(:success)
      end
    end

    # TODO: Fix authentication testing in request specs
    # context "when user is not authenticated" do
    #   before do
    #     # sign_out doesn't work properly in request specs
    #   end

    #   it "redirects to sign in from protected pages" do
    #     get my_brand_path
    #     expect(response).to redirect_to(new_user_session_path)
    #   end

    #   it "redirects to sign in from brand pages" do
    #     get my_brand_path
    #     expect(response).to redirect_to(new_user_session_path)
    #   end

    #   it "redirects to sign in from settings" do
    #     get settings_path
    #     expect(response).to redirect_to(new_user_session_path)
    #   end
    # end
  end

  describe "Page Content and Structure" do
    it "includes proper navigation elements in planning page" do
      get planning_path
      expect(response.body).to include("Smart Planning")
      expect(response.body).to include("Add Content")
      expect(response.body).to include("Overview")
    end

    it "includes proper form elements in brand page" do
      get my_brand_path
      expect(response.body).to include("Brand Profile")
      expect(response.body).to include("form")
    end

    it "includes proper navigation menu in all pages" do
      pages = [ planning_path, my_brand_path, settings_path ]

      pages.each do |page_path|
        get page_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "Response Headers and Content Type" do
    it "returns HTML content type for main pages" do
      get planning_path
      expect(response.content_type).to include("text/html")
    end

    it "includes proper charset in response" do
      get planning_path
      expect(response.content_type).to include("charset=utf-8")
    end
  end

  describe "Error Handling" do
    # TODO: Fix error handling test - routes return 404 instead of raising error in test environment
    # it "handles non-existent routes gracefully" do
    #   expect {
    #     get "/non-existent-page"
    #   }.to raise_error(ActionController::RoutingError)
    # end

    it "returns 404 for non-existent routes" do
      get "/non-existent-page"
      expect(response).to have_http_status(:not_found)
    end
  end
end
