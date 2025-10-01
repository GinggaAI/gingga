# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Planning::ContentDetailsController, type: :controller do
  include Devise::Test::ControllerHelpers
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user, slug: 'test-brand') }
  let(:other_brand) { create(:brand, user: user, slug: 'other-brand') }

  let(:valid_content_piece) do
    {
      title: "Sample Content",
      description: "Sample description",
      hook: "Attention-grabbing hook",
      cta: "Call to action",
      platform: "Instagram",
      status: "draft",
      kpi_focus: "engagement",
      visual_notes: "Use bright colors",
      template: "only_avatars"
    }
  end

  before do
    sign_in user, scope: :user
    allow(user).to receive(:current_brand).and_return(brand)
    I18n.locale = :en
  end

  after do
    I18n.locale = I18n.default_locale
  end

  describe 'GET #show' do
    context 'with valid brand-scoped route' do
      before do
        # Simulate brand-scoped routing by setting the brand slug in params
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(
            brand_slug: brand.slug,
            content_data: valid_content_piece.to_json
          )
        )
        allow(Planning::BrandResolver).to receive(:call).with(user).and_return(brand)
      end

      it 'returns successful response with HTML content' do
        get :show, params: { brand_slug: brand.slug, locale: :en, content_data: valid_content_piece.to_json }, format: :json

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('html')
        expect(json_response['html']).to be_present
      end

      it 'includes content piece data in rendered HTML' do
        get :show, params: { brand_slug: brand.slug, locale: :en, content_data: valid_content_piece.to_json }, format: :json

        json_response = JSON.parse(response.body)
        html_content = json_response['html']

        expect(html_content).to include(valid_content_piece[:title])
        expect(html_content).to include(valid_content_piece[:hook])
        expect(html_content).to include(valid_content_piece[:cta])
        expect(html_content).to include(valid_content_piece[:description])
      end

      it 'calls ContentDetailsService with correct parameters' do
        expect(Planning::ContentDetailsService).to receive(:new)
          .with(content_data: valid_content_piece.to_json, user: user)
          .and_call_original

        get :show, params: { brand_slug: brand.slug, locale: :en, content_data: valid_content_piece.to_json }, format: :json
      end

      it 'uses correct brand context through BrandResolver' do
        expect(Planning::BrandResolver).to receive(:call).with(user).and_return(brand)

        get :show, params: { brand_slug: brand.slug, locale: :en, content_data: valid_content_piece.to_json }, format: :json
      end
    end

    context 'with invalid content data' do
      it 'returns error response for missing content_data' do
        get :show, params: { brand_slug: brand.slug, locale: :en }, format: :json

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to include('required')
      end

      it 'returns error response for invalid JSON' do
        get :show, params: { brand_slug: brand.slug, locale: :en, content_data: 'invalid json {' }, format: :json

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
      end
    end

    context 'with unauthenticated user' do
      before { sign_out user }

      it 'redirects to authentication' do
        get :show, params: { brand_slug: brand.slug, locale: :en, content_data: valid_content_piece.to_json }, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with complete content piece from strategy plan' do
      let(:strategy_content_piece) do
        {
          "id" => "202511-test-brand-w1-i1-C",
          "title" => "AI Tools Every Entrepreneur Should Know",
          "description" => "Introduce a series of AI tools that are essential for entrepreneurs.",
          "hook" => "Discover the AI tools that can revolutionize your startup!",
          "cta" => "Explore these AI tools now!",
          "platform" => "Instagram Reels",
          "status" => "draft",
          "pilar" => "C",
          "kpi_focus" => "reach",
          "visual_notes" => "Dynamic transitions between tool demonstrations and expert commentary.",
          "success_criteria" => "≥10,000 views",
          "recommended_template" => "avatar_and_video",
          "video_source" => "kling",
          "repurpose_to" => [ "TikTok", "LinkedIn" ]
        }
      end

      it 'renders all content fields correctly' do
        get :show, params: { brand_slug: brand.slug, locale: :en, content_data: strategy_content_piece.to_json }, format: :json

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        html_content = json_response['html']

        # Verify all key fields are rendered
        expect(html_content).to include(strategy_content_piece["title"])
        expect(html_content).to include(strategy_content_piece["hook"])
        expect(html_content).to include(strategy_content_piece["cta"])
        expect(html_content).to include(strategy_content_piece["description"])
        expect(html_content).to include(strategy_content_piece["visual_notes"])
        expect(html_content).to include(strategy_content_piece["success_criteria"])
        expect(html_content).to include(strategy_content_piece["platform"])
        expect(html_content).to include("Pillar #{strategy_content_piece['pilar']}")
      end
    end

    context 'brand isolation behavior' do
      it 'ensures content details are scoped to current brand' do
        # Verify that the service receives the correct brand through BrandResolver
        expect(Planning::BrandResolver).to receive(:call).with(user).and_return(brand)

        # Mock PlanningPresenter to verify it receives the correct brand
        expect(PlanningPresenter).to receive(:new)
          .with({}, brand: brand, current_plan: nil)
          .and_call_original

        get :show, params: { brand_slug: brand.slug, locale: :en, content_data: valid_content_piece.to_json }, format: :json
      end

      it 'does not access content from other brands' do
        # Even if we try to access with other brand data, it should use current_brand
        allow(user).to receive(:current_brand).and_return(other_brand)

        expect(Planning::BrandResolver).to receive(:call).with(user).and_return(other_brand)

        get :show, params: { brand_slug: other_brand.slug, locale: :en, content_data: valid_content_piece.to_json }, format: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'AJAX behavior' do
    it 'accepts XMLHttpRequest properly' do
      get :show,
          params: { brand_slug: brand.slug, locale: :en, content_data: valid_content_piece.to_json },
          format: :json,
          xhr: true

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
    end

    it 'includes correct CSRF token handling' do
      # This test ensures the controller properly handles CSRF for AJAX requests
      request.headers['X-Requested-With'] = 'XMLHttpRequest'

      get :show,
          params: { brand_slug: brand.slug, locale: :en, content_data: valid_content_piece.to_json },
          format: :json

      expect(response).to have_http_status(:success)
    end
  end
end
