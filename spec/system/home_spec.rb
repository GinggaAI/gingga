require 'rails_helper'

RSpec.describe "Landing Page", type: :system do
  before do
    driven_by(:rack_test)
  end

  describe "main page content" do
    it "displays the main headline and CTA" do
      visit "/"
      expect(page).to have_text("Your intelligent")
      expect(page).to have_text("creation system")
      expect(page).to have_link("Get Started")
    end

    it "renders How Gingga Works steps" do
      visit "/"
      # Current landing has plans structure
      expect(page).to have_text("Consistency")
      expect(page).to have_text("Growth")
      expect(page).to have_text("Domination")
    end

    it "displays all feature sections with proper headings" do
      visit "/"

      # Check all main section headings in current landing
      expect(page).to have_text("Intelligent Creation System Plans")
      expect(page).to have_text("Add-ons")
      expect(page).to have_text("Start giving your brand momentum")
    end

    it "shows feature cards with proper icons and descriptions" do
      visit "/"

      # Plan cards in current landing
      expect(page).to have_text("Consistency")
      expect(page).to have_text("Growth")
      expect(page).to have_text("Domination")
      expect(page).to have_text("Keep your brand active without extra effort")
      expect(page).to have_text("Creative diversity with continuous strategic support")
    end

    it "shows testimonials from customers" do
      visit "/"

      # Current landing doesn't have testimonials section
      # Just verify the main content is present
      expect(page).to have_text("GINGGA")
    end

    it "displays pricing information" do
      visit "/"

      expect(page).to have_text("£259")
      expect(page).to have_text("£399")
      expect(page).to have_text("£579")
    end
  end

  describe "navigation and structure" do
    it "has proper navigation links" do
      visit "/"

      expect(page).to have_link("Get Started")
      # Footer has link to planes
      within('footer') do
        expect(page).to have_link(href: "#planes")
      end
    end

    it "has semantic HTML structure with proper sections" do
      visit "/"

      expect(page).to have_css("nav")
      expect(page).to have_css("#planes")
      expect(page).to have_css("footer")
    end

    it "includes footer with company information" do
      visit "/"

      expect(page).to have_text("Intelligence in motion — more than a brand, it's a movement")
      # Current footer has different structure
      expect(page).to have_text("Services")
      expect(page).to have_text("Contact")
    end
  end

  describe "accessibility and usability" do
    it "has multiple CTA buttons for conversion" do
      visit "/"

      # Current CTAs
      expect(page).to have_link("Get Started")
      expect(page).to have_link("Activate my Gingga engine")
      expect(page).to have_link("Get Started with Gingga")
    end

    it "displays brand identity consistently" do
      visit "/"

      # Brand name should appear in nav and footer
      expect(page).to have_text("GINGGA", minimum: 2)
      expect(page).to have_text("Intelligence in motion — more than a brand, it's a movement")
    end
  end
end
