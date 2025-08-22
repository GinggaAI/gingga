require 'rails_helper'

RSpec.feature "Home", type: :feature do
  scenario "User visits the home page and sees all landing page content" do
    visit root_path

    # Hero section
    expect(page).to have_text("One place. All your content. Powered by AI, guided by your voice.")
    expect(page).to have_text("Gingga makes it easy for everyday creators to publish high-quality content fast—without being techy.")
    expect(page).to have_text("AI, Already Done For You")

    # Navigation
    expect(page).to have_link("How it works")
    expect(page).to have_link("Get Started")

    # What You Get section - updated to new 4-box structure
    expect(page).to have_text("What You Get")
    expect(page).to have_text("Noctua (The Strategist)")
    expect(page).to have_text("Voxa (The Voice Constructor)")
    expect(page).to have_text("Sagui (The Prompt Crafter)")
    expect(page).to have_text("Alumo (Your Sales Assistant)")
    expect(page).to have_text("Brand mapping and content clarity—so every post reflects your voice.")
    expect(page).to have_text("From raw ideas to practical scripts, complete with images and post descriptions.")
    expect(page).to have_text("Smart prompts turned into ready-to-use posts.")
    expect(page).to have_text("Replies, captures leads, and books clients automatically.")

    # Why Small Brands Choose Gingga section
    expect(page).to have_text("Why small brands choose Gingga")
    expect(page).to have_text("Show up daily without burnout.")
    expect(page).to have_text("Keep your voice. Multiply your output.")
    expect(page).to have_text("Intelligence that learns and compounds every week.")
    expect(page).to have_text("Brand-first: clarity → ideas → execution")
    expect(page).to have_text("No complex tools or constant meetings")
    expect(page).to have_text("Results that grow with rhythm and consistency")

    # How it works section
    expect(page).to have_text("How it works")
    expect(page).to have_text("Noctua maps your brand")
    expect(page).to have_text("Sagui spins prompts into ideas")
    expect(page).to have_text("Voxa crafts visuals")
    expect(page).to have_text("Alumo anchors the rhythm")
    expect(page).to have_text("Voice, values, audience and goals in one simple intake.")


    # Testimonials section
    expect(page).to have_text("What people are saying")
    expect(page).to have_text("I used to dread content days. Now it flows.")
    expect(page).to have_text("Camila — Wellness Coach")
    expect(page).to have_text("Feels like magic. Clients think I hired a team.")
    expect(page).to have_text("Luis — Barbershop Owner")

    # Pricing section
    expect(page).to have_text("Choose your rhythm")
    expect(page).to have_text("£248/mo")
    expect(page).to have_text("£585/mo")
    expect(page).to have_text("£748/mo")
    expect(page).to have_text("£1,498/mo")
    expect(page).to have_text("Book a free discovery call")
    expect(page).to have_text("Start with a free discovery call. ProSumer pricing available if you run Gingga for yourself.")

    # Footer
    expect(page).to have_text("Intelligence in Motion")
    expect(page).to have_link("Privacy Policy")
    expect(page).to have_link("Terms of Service")
    expect(page).to have_link("Contact")
  end

  scenario "User can interact with CTA buttons" do
    visit root_path

    # Check for different CTA buttons
    expect(page).to have_link("Get Started") # Navigation
    expect(page).to have_link("Start Now") # Hero section
    expect(page).to have_link("Book a free discovery call") # Pricing sections

    # Verify buttons are present and clickable in specific sections
    within('header') do
      expect(page).to have_link("Get Started")
    end

    within('#cta') do
      expect(page).to have_link("Book a free discovery call")
    end

    # Verify we have multiple CTA buttons/links across the page
    expect(all('a', text: /Get Started|Start Now|Book a free discovery call/).count).to be >= 2
  end

  scenario "User can navigate using anchor links" do
    visit root_path

    # Test navigation links exist and have proper href attributes
    expect(page).to have_link("How it works", href: "#how")
  end

  scenario "Page displays proper brand elements and styling" do
    visit root_path

    # Check that brand elements are present
    expect(page).to have_text("GINGGA") # Brand logo in header and footer
    expect(page).to have_text("Intelligence in Motion") # Brand tagline

    # Check section IDs for proper navigation
    expect(page).to have_css("#how")
    expect(page).to have_css("#cta")

    # Check for proper sections
    expect(page).to have_css("header")
    expect(page).to have_css("footer")
  end
end
