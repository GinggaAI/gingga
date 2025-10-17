require 'rails_helper'

RSpec.describe SettingsController, type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    sign_in user, scope: :user
    user.update_last_brand(brand)
  end

  describe 'GET #show' do
    it 'renders successfully' do
      get settings_path(brand_slug: brand.slug, locale: :en)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('API Integrations Overview')
    end
  end
end
