require 'rails_helper'

RSpec.describe "Landing Page", type: :system do
  before do
    driven_by(:rack_test)
  end

  describe "main page content" do
    it "displays the main headline and CTA" do
      visit root_path
      expect(page).to have_text("One place. All your content. Powered by AI, guided by your voice.")
      expect(page).to have_link("Get Started")
    end

    it "renders How Gingga Works steps" do
      visit root_path
      expect(page).to have_text("Noctua maps your brand")
      expect(page).to have_text("Sagui spins prompts into ideas")
      expect(page).to have_text("Voxa crafts visuals")
      expect(page).to have_text("Alumo anchors the rhythm")
    end

    it "displays all feature sections with proper headings" do
      visit root_path

      # Check all main section headings
      expect(page).to have_text("What You Get")
      expect(page).to have_text("Why small brands choose Gingga")
      expect(page).to have_text("How it works")
      expect(page).to have_text("What people are saying")
      expect(page).to have_text("Choose your rhythm")
    end

    it "shows feature cards with proper icons and descriptions" do
      visit root_path

      # Feature cards - updated to new 4-box structure
      expect(page).to have_text("Noctua (The Strategist)")
      expect(page).to have_text("Voxa (The Voice Constructor)")
      expect(page).to have_text("Sagui (The Prompt Crafter)")
      expect(page).to have_text("Alumo (Your Sales Assistant)")
      expect(page).to have_text("Brand mapping and content clarity—so every post reflects your voice.")
      expect(page).to have_text("From raw ideas to practical scripts, complete with images and post descriptions.")
    end


    it "shows testimonials from customers" do
      visit root_path

      expect(page).to have_text("I used to dread content days. Now it flows.")
      expect(page).to have_text("Camila — Wellness Coach")
      expect(page).to have_text("Feels like magic. Clients think I hired a team.")
      expect(page).to have_text("Luis — Barbershop Owner")
    end

    it "displays pricing information" do
      visit root_path

      expect(page).to have_text("£248/mo")
      expect(page).to have_text("£585/mo")
      expect(page).to have_text("£748/mo")
      expect(page).to have_text("£1,498/mo")
      expect(page).to have_text("Book a free discovery call")
    end
  end

  describe "navigation and structure" do
    it "has proper navigation links" do
      visit root_path

      expect(page).to have_link("How it works", href: "#how")
      expect(page).to have_link("Get Started")
    end

    it "has semantic HTML structure with proper sections" do
      visit root_path

      expect(page).to have_css("header")
      expect(page).to have_css("section#how")
      expect(page).to have_css("section#cta")
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

      # Should have Get Started and Start Now links
      expect(page).to have_link("Get Started")
      expect(page).to have_link("Start Now")
      expect(page).to have_link("Book a free discovery call", count: 4)
    end

    it "displays brand identity consistently" do
      visit root_path

      # Brand name should appear in nav and footer
      expect(page).to have_text("GINGGA", count: 2) # Nav and footer
      expect(page).to have_text("Intelligence in Motion")
    end
  end
end
