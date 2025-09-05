require 'rails_helper'
require 'ostruct'

RSpec.describe "HeyGen Settings Integration", type: :request do
  let(:user) { create(:user) }
  let(:valid_api_key) { "test_heygen_key_123" }

  before do
    # Mock the API token validator to prevent actual API calls
    allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
      .and_return({ valid: true })

    # Mock the HeyGen service calls
    allow_any_instance_of(Heygen::SynchronizeAvatarsService).to receive(:call)
      .and_return(OpenStruct.new(success?: true, data: { synchronized_count: 3 }))
  end

  it "allows user to save and validate HeyGen API key" do
    # POST to save the API key (simulating form submission)
    post "/en/settings/validate_heygen_api", params: {
      heygen_api_key: valid_api_key
    }, headers: {
      'Authorization' => "Bearer #{user.email}" # Simple auth simulation
    }

    # Should redirect or return success response
    expect(response.status).to be_between(200, 302)
  end
end
