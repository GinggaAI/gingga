require 'rails_helper'

RSpec.describe "HeyGen Settings Integration", type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:valid_api_key) { "test_heygen_key_123" }

  before do
    sign_in user, scope: :user
    user.update_last_brand(brand)

    # Mock the API token validator to prevent actual API calls
    allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
      .and_return({ valid: true })

    # Mock the HeyGen service calls
    mock_result = Struct.new(:success?, :data, :error, keyword_init: true).new(
      success?: true,
      data: { synchronized_count: 3 },
      error: nil
    )
    allow_any_instance_of(Heygen::ValidateAndSyncService).to receive(:call)
      .and_return(mock_result)
  end

  it "allows user to save and validate HeyGen API key" do
    # POST to validate the API key using the new route
    post validate_api_integration_path(provider: 'heygen', brand_slug: brand.slug, locale: 'en'), params: {
      heygen_api_key: valid_api_key
    }

    # Should redirect or return success response
    expect(response.status).to be_between(200, 302)
  end
end
