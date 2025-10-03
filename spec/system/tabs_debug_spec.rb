# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Settings Tabs Functionality', type: :system do
  include Warden::Test::Helpers

  before do
    driven_by(:rack_test)
    @user = create(:user)
    @brand = create(:brand, user: @user)
    @user.update_last_brand(@brand)
  end

  after do
    Warden.test_reset!
  end

  it 'displays the settings page with correct tab structure' do
    login_as(@user, scope: :user)
    visit settings_path(brand_slug: @brand.slug, locale: :en)

    # Verify basic functionality
    expect(page).to have_content('Settings')
    expect(page).to have_css('[data-controller="tabs"]')
    expect(page).to have_css('[data-tabs-target="tab"]', count: 3)

    # Check for panels (including hidden ones)
    panels = page.all('[data-tabs-target="panel"]', visible: :all)
    expect(panels.count).to eq(3)

    # Check tab buttons functionality
    tab_buttons = page.all('[data-tabs-target="tab"]', visible: :all)
    expect(tab_buttons.length).to eq(3)

    # Check if Account panel exists
    account_panel = page.find('#radix-«r72»-content-account', visible: :all)
    expect(account_panel).to be_present

    # Check data actions
    click_actions = page.all('[data-action*="tabs#switchTab"]', visible: :all)
    expect(click_actions.length).to eq(3)
  end

  it 'contains the language switcher in the Account panel' do
    login_as(@user, scope: :user)
    visit settings_path(brand_slug: @brand.slug, locale: :en)

    # Verify Account panel contains language switcher HTML structure
    account_panel = page.find('#radix-«r72»-content-account', visible: :all)
    within account_panel do
      # Check for language switcher component presence (HTML exists even if hidden)
      expect(page.body).to include('Language Settings')
      expect(page.body).to include('/en/settings')
      expect(page.body).to include('/es/settings')
      expect(page.body).to include('English')
      expect(page.body).to include('Spanish')
      expect(page.body).to include('🇺🇸')
      expect(page.body).to include('🇪🇸')
    end
  end
end
