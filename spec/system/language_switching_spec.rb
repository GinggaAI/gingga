# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Language Switching', type: :system do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    driven_by(:rack_test)
    sign_in user, scope: :user
    user.update_last_brand(brand)
  end

  describe 'in settings page' do
    it 'contains language switcher in the HTML' do
      visit settings_path(brand_slug: brand.slug, locale: :en)

      # Should show English by default
      expect(page).to have_content('Settings')

      # The language switcher should be present in the Account panel HTML (even if hidden)
      account_panel = page.find('#radix-«r72»-content-account', visible: :all)
      expect(account_panel.native.inner_html).to include('Language Settings')
      expect(account_panel.native.inner_html).to include('English')
      expect(account_panel.native.inner_html).to include('Spanish')
    end

    it 'allows switching from Spanish back to English while staying on settings page' do
      # Start on Spanish settings page
      visit settings_path(brand_slug: brand.slug, locale: :es)
      expect(page).to have_content('Configuración')

      # The language switcher should be in the Account panel with proper links
      account_panel = page.find('#radix-«r72»-content-account', visible: :all)
      account_html = account_panel.native.inner_html

      # Should have a link to English settings with brand context preserved
      expect(account_html).to include("href=\"/#{brand.slug}/en/settings\"")
      # Should have English language option in Spanish (since we're on Spanish page)
      expect(account_html).to include('Inglés')
      # Should have Spanish language option
      expect(account_html).to include('Español')

      # Spanish should be marked as current (with styling)
      expect(account_html).to include('bg-indigo-100 border-indigo-200 text-indigo-700')
    end

    it 'generates correct paths in language switcher based on current page' do
      # Test from English settings page - should stay on settings
      visit "/en/settings"
      account_panel = page.find('#radix-«r72»-content-account', visible: :all)
      account_html = account_panel.native.inner_html

      # Should have link to Spanish settings and English settings
      expect(account_html).to include('href="/es/settings"') # Spanish settings
      expect(account_html).to include("href=\"/#{brand.slug}/en/settings\"") # English settings

      # English should be marked as current (with styling)
      expect(account_html).to include('bg-indigo-100 border-indigo-200 text-indigo-700')
    end

    it 'navigates correctly between languages maintaining settings context' do
      # Start on Spanish settings page
      visit settings_path(brand_slug: brand.slug, locale: :es)
      expect(page).to have_content('Configuración')

      # Extract the English link from the Account panel
      account_panel = page.find('#radix-«r72»-content-account', visible: :all)
      account_html = account_panel.native.inner_html

      # Extract href for English link (should be /en/settings to set locale properly)
      expect(account_html).to include("href=\"/#{brand.slug}/en/settings\"")
      english_href = "/en/settings"

      # Navigate to English settings
      visit english_href

      # Should now be on English settings page
      expect(page).to have_content('Settings')
      expect(current_path).to eq('/en/settings')

      # Check that English is now marked as current
      account_panel = page.find('#radix-«r72»-content-account', visible: :all)
      account_html = account_panel.native.inner_html

      # English should be marked as current (with blue styling)
      expect(account_html).to include('bg-indigo-100 border-indigo-200 text-indigo-700')
      expect(account_html).to include('English')
    end
  end

  describe 'direct URL navigation' do
    it 'loads Spanish version when visiting Spanish URL' do
      visit settings_path(brand_slug: brand.slug, locale: :es)
      expect(page).to have_content('Configuración')
      expect(page).to have_content('Gestiona las preferencias')
    end

    it 'loads English version when visiting English URL' do
      visit "/en/settings"
      expect(page).to have_content('Settings')
      expect(page).to have_content('Manage')
    end
  end
end
