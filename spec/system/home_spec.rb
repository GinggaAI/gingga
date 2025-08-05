require 'rails_helper'

RSpec.describe "Landing Page", type: :system do
  before do
    driven_by(:rack_test)
  end

  describe "main page content" do
    it "displays the main headline and CTA" do
      visit root_path
      expect(page).to have_text("GINGGA: Intelligence in Motion")
      expect(page).to have_button("Get Started Now")
    end

    it "renders How Gingga Works steps" do
      visit root_path
      expect(page).to have_text("Tell us about your brand")
      expect(page).to have_text("We create your content engine")
      expect(page).to have_text("You approve. We schedule.")
      expect(page).to have_text("Your brand shows up. And grows.")
    end

    it "displays all feature sections with proper headings" do
      visit root_path

      # Check all main section headings
      expect(page).to have_text("What Gingga Does")
      expect(page).to have_text("Why Small Brands Choose Gingga")
      expect(page).to have_text("How Gingga Works")
      expect(page).to have_text("Meet the Gingga Guides")
      expect(page).to have_text("What People Are Saying")
      expect(page).to have_text("Start Growing — Without Burning Out")
    end

    it "shows feature cards with proper icons and descriptions" do
      visit root_path

      # Feature cards
      expect(page).to have_text("Monthly Content Calendar")
      expect(page).to have_text("AI-Powered Visuals")
      expect(page).to have_text("Smart Scheduling")
      expect(page).to have_text("Intelligent Replies")
      expect(page).to have_text("Adaptive Learning")
    end

    it "displays all Gingga Guide characters" do
      visit root_path

      expect(page).to have_text("Noctua")
      expect(page).to have_text("Clarifies your brand's message")
      expect(page).to have_text("Sagui")
      expect(page).to have_text("Sparks content ideas with real-time prompts")
      expect(page).to have_text("Voxa")
      expect(page).to have_text("Brings your visuals and videos to life")
      expect(page).to have_text("Alumo")
      expect(page).to have_text("Turns followers into long-term clients")
    end

    it "shows testimonials from customers" do
      visit root_path

      expect(page).to have_text("I used to dread content days. Now it all just flows. Gingga gets my brand.")
      expect(page).to have_text("Camila")
      expect(page).to have_text("Wellness Coach")
      expect(page).to have_text("This feels like magic. Clients think I hired a whole team.")
      expect(page).to have_text("Luis")
      expect(page).to have_text("Barbershop Owner")
    end

    it "displays pricing information" do
      visit root_path

      expect(page).to have_text("£98")
      expect(page).to have_text("Plans from £98/month")
      expect(page).to have_text("First month: 20% off")
      expect(page).to have_text("Book a free discovery call or start today")
    end
  end

  describe "navigation and structure" do
    it "has proper navigation links" do
      visit root_path

      expect(page).to have_link("Features", href: "#features")
      expect(page).to have_link("How It Works", href: "#how-it-works")
      expect(page).to have_link("Guides", href: "#guides")
      expect(page).to have_link("Pricing", href: "#pricing")
    end

    it "has semantic HTML structure with proper sections" do
      visit root_path

      expect(page).to have_css("header")
      expect(page).to have_css("main")
      expect(page).to have_css("section#features")
      expect(page).to have_css("section#how-it-works")
      expect(page).to have_css("section#guides")
      expect(page).to have_css("section#pricing")
      expect(page).to have_css("footer")
    end

    it "includes footer with company information" do
      visit root_path

      expect(page).to have_text("Intelligence in Motion")
      expect(page).to have_link("Privacy Policy")
      expect(page).to have_link("Terms of Service")
      expect(page).to have_link("Contact")
    end
  end

  describe "accessibility and usability" do
    it "has multiple CTA buttons for conversion" do
      visit root_path

      # Should have at least 2 Get Started buttons
      expect(all('button', text: /Get Started/).count).to be >= 2
    end

    it "displays brand identity consistently" do
      visit root_path

      # Brand name should appear in multiple places
      expect(page).to have_text("🌀 GINGGA", count: 2) # Nav and footer
      expect(page).to have_text("GINGGA:", count: 1) # Hero
    end
  end
end
