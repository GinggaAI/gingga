require 'rails_helper'

RSpec.feature "Home", type: :feature do
  scenario "User visits the home page and sees all landing page content" do
    visit "/"

    # Hero section
    expect(page).to have_text("Your intelligent")
    expect(page).to have_text("creation system")
    expect(page).to have_text("Turn your voice, ideas, and presence into a constant flow of professional content with AI")

    # Navigation
    expect(page).to have_link("Get Started")

    # Fase 2 - Planes section
    expect(page).to have_text("Intelligent Creation System Plans")
    expect(page).to have_text("Consistency")
    expect(page).to have_text("Growth")
    expect(page).to have_text("Domination")

    # Pricing
    expect(page).to have_text("£259")
    expect(page).to have_text("£399")
    expect(page).to have_text("£579")

    # Add-ons section
    expect(page).to have_text("Add-ons")
    expect(page).to have_text("Additional reel creation")
    expect(page).to have_text("Package of 10 scripts")
    expect(page).to have_text("Brand Intelligence Kit")

    # CTA Final
    expect(page).to have_text("Start giving your brand momentum")
    expect(page).to have_link("Get Started with Gingga")

    # Footer
    expect(page).to have_text("GINGGA")
    expect(page).to have_text("Intelligence in motion — more than a brand, it's a movement")
  end

  scenario "User can interact with CTA buttons" do
    visit "/"

    # Check for CTA buttons
    expect(page).to have_link("Get Started") # Navigation
    expect(page).to have_link("Activate my Gingga engine") # Hero section
    expect(page).to have_link("Get Started with Gingga") # CTA Final

    # Verify buttons are present in header
    within('nav') do
      expect(page).to have_link("Get Started")
    end

    # Verify we have multiple CTA buttons/links across the page
    expect(all('a', text: /Get Started|Activate my Gingga engine/).count).to be >= 2
  end

  scenario "User can navigate using anchor links" do
    visit "/"

    # Test navigation links exist - link to planes section
    within('footer') do
      expect(page).to have_link(href: "#planes")
    end
  end

  scenario "Page displays proper brand elements and styling" do
    visit "/"

    # Check that brand elements are present
    expect(page).to have_text("GINGGA") # Brand logo in header and footer
    expect(page).to have_text("Intelligence in motion — more than a brand, it's a movement") # Brand tagline

    # Check section IDs for proper navigation
    expect(page).to have_css("#planes")

    # Check for proper sections
    expect(page).to have_css("nav")
    expect(page).to have_css("footer")
  end
end
