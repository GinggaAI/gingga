# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Settings Tabs', type: :system do
  before do
    driven_by(:rack_test)
    # Create a user for the test (ApplicationController will use User.first in test env)
    create(:user)
  end

  it 'renders the settings page with all tabs' do
    visit settings_path

    # Should show all tabs
    expect(page).to have_button('API Integrations')
    expect(page).to have_button('Account')
    expect(page).to have_button('Security')

    # Should show API Integrations content by default
    expect(page).to have_content('API Integrations Overview')

    # Should have the tabs controller data attributes
    expect(page).to have_css('[data-controller="tabs"]')
    expect(page).to have_css('[data-tabs-target="tab"]')
    expect(page).to have_css('[data-tabs-target="panel"]')
  end

  it 'has language switcher in Account tab content (hidden by default)' do
    create(:user) # Create user for this test too
    visit settings_path

    # Language switcher content should be present in the DOM (Account tab content exists but is hidden)
    expect(page).to have_css('#radix-«r72»-content-account', visible: :all)
    account_panel = page.find('#radix-«r72»-content-account', visible: :all)

    # Check the raw HTML content since rack_test driver may not show hidden elements properly
    expect(account_panel.native.inner_html).to include('Language Settings')
    expect(account_panel.native.inner_html).to include('English')
    expect(account_panel.native.inner_html).to include('Spanish')
  end
end
