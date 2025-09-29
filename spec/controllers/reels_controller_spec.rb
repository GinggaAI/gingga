require 'rails_helper'

RSpec.describe "ReelsController", type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    sign_in user, scope: :user
    user.update_last_brand(brand)
  end

  describe "GET scene-based reels (new action)" do
    it "returns success and shows form" do
      get scene_based_reels_path(brand_slug: brand.slug, locale: :en)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('form')
    end

    it "does not create database records during GET" do
      # This test prevents the regression that caused the original bug
      expect {
        get scene_based_reels_path(brand_slug: brand.slug, locale: :en)
        get scene_based_reels_path(brand_slug: brand.slug, locale: :en) # Multiple requests
      }.not_to change(Reel, :count)
    end

    it "creates form with POST method, not PATCH" do
      # This would have caught the original bug
      get scene_based_reels_path(brand_slug: brand.slug, locale: :en)

      doc = Nokogiri::HTML(response.body)
      form = doc.css('form').first

      expect(form['method']).to eq('post'), "Form must use POST for new records"
      expect(form['action']).to match(%r{/reels/scene-based$|/en/reels$}), "Form must post to correct path"

      # Critical: no _method=PATCH field (which would route to non-existent endpoint)
      method_override = doc.css("input[name='_method'][value='patch']").first
      expect(method_override).to be_nil, "Must not have _method=PATCH"
    end
  end

  describe "POST scene-based reels (create action)" do
    let(:valid_params) do
      {
        reel: {
          template: "only_avatars",
          title: "Test Reel"
        }
      }
    end

    it "creates reel and redirects" do
      expect {
        post scene_based_reels_path(brand_slug: brand.slug, locale: :en), params: valid_params
      }.to change(Reel, :count).by(1)

      expect(response).to have_http_status(:redirect)
    end

    it "routes correctly - no 404 errors" do
      # This test verifies the bug is fixed
      post scene_based_reels_path(brand_slug: brand.slug, locale: :en), params: valid_params

      expect(response).not_to have_http_status(:not_found)
      expect(response).not_to have_http_status(:method_not_allowed)
    end
  end

  describe "Smart planning integration" do
    let(:smart_planning_data) do
      {
        title: "Preloaded Reel",
        shotplan: {
          scenes: [
            { voiceover: "Scene 1 script", avatar_id: "avatar_1" }
          ]
        }
      }.to_json
    end

    it "handles smart planning data without creating records" do
      expect {
        get scene_based_reels_path(brand_slug: brand.slug, locale: :en), params: { smart_planning_data: smart_planning_data }
      }.not_to change(Reel, :count)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Preloaded Reel")
    end
  end
end
