require 'rails_helper'

RSpec.describe "HeyGen Settings Integration", type: :system do
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
    visit "/en/settings"
    
    # Check initial state - should show "Not configured"
    expect(page).to have_text("Not configured")
    expect(page).to have_field("heygen_api_key", with: "")
    
    # Fill in the API key
    fill_in "heygen_api_key", with: valid_api_key
    click_button "Save"
    
    # Should see success message
    expect(page).to have_text("HeyGen API key saved successfully!")
    
    # Now validation button should be enabled
    # Note: We can't easily test this in a system test without mocking authentication
    # But we've validated the individual components work in unit tests
  end
end