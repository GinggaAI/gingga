require 'rails_helper'

RSpec.feature "Home", type: :feature do
  scenario "User visits the home page and sees all landing page content" do
    visit root_path
    
    # Hero section
    expect(page).to have_text("GINGGA: Intelligence in Motion")
    expect(page).to have_text("Your brand deserves to move, grow, and glow — every day.")
    expect(page).to have_text("We help small businesses turn raw ideas into ready-to-publish content")
    expect(page).to have_text("No marketing team. No complex tools. Just you — and Gingga doing the heavy lifting.")
    
    # Navigation
    expect(page).to have_link("Features")
    expect(page).to have_link("How It Works")
    expect(page).to have_link("Guides")
    expect(page).to have_link("Pricing")
    
    # What Gingga Does section
    expect(page).to have_text("What Gingga Does")
    expect(page).to have_text("From scattered ideas to scroll-stopping content — in minutes.")
    expect(page).to have_text("Monthly Content Calendar")
    expect(page).to have_text("AI-Powered Visuals")
    expect(page).to have_text("Smart Scheduling")
    expect(page).to have_text("Intelligent Replies")
    expect(page).to have_text("Adaptive Learning")
    expect(page).to have_text("You don't need to be a content expert. Just be you. We'll do the rest.")
    
    # Why Small Brands Choose Gingga section
    expect(page).to have_text("Why Small Brands Choose Gingga")
    expect(page).to have_text("Most small businesses struggle to show up online.")
    expect(page).to have_text("Gingga makes it effortless — and effective.")
    expect(page).to have_text("No tech overwhelm")
    expect(page).to have_text("Saves you hours")
    expect(page).to have_text("Drives real conversations")
    expect(page).to have_text("AI + Human brilliance")
    
    # How Gingga Works section
    expect(page).to have_text("How Gingga Works")
    expect(page).to have_text("Tell us about your brand")
    expect(page).to have_text("We create your content engine")
    expect(page).to have_text("You approve. We schedule.")
    expect(page).to have_text("Your brand shows up. And grows.")
    
    # Meet the Gingga Guides section
    expect(page).to have_text("Meet the Gingga Guides")
    expect(page).to have_text("Your creative crew behind the screen")
    expect(page).to have_text("They're not just characters. They're your co-creators.")
    expect(page).to have_text("Noctua")
    expect(page).to have_text("Clarifies your brand's message")
    expect(page).to have_text("Sagui")
    expect(page).to have_text("Sparks content ideas with real-time prompts")
    expect(page).to have_text("Voxa")
    expect(page).to have_text("Brings your visuals and videos to life")
    expect(page).to have_text("Alumo")
    expect(page).to have_text("Turns followers into long-term clients")
    
    # Testimonials section
    expect(page).to have_text("What People Are Saying")
    expect(page).to have_text("I used to dread content days. Now it all just flows. Gingga gets my brand.")
    expect(page).to have_text("Camila")
    expect(page).to have_text("Wellness Coach")
    expect(page).to have_text("This feels like magic. Clients think I hired a whole team.")
    expect(page).to have_text("Luis")
    expect(page).to have_text("Barbershop Owner")
    
    # Pricing section
    expect(page).to have_text("Start Growing — Without Burning Out")
    expect(page).to have_text("Plans from £98/month")
    expect(page).to have_text("First month: 20% off")
    expect(page).to have_text("Book a free discovery call or start today")
    expect(page).to have_text("Ready to transform your content strategy?")
    
    # Footer
    expect(page).to have_text("Intelligence in Motion")
    expect(page).to have_link("Privacy Policy")
    expect(page).to have_link("Terms of Service")
    expect(page).to have_link("Contact")
  end
  
  scenario "User can interact with CTA buttons" do
    visit root_path
    
    # Check for different CTA buttons
    expect(page).to have_button("Get Started") # Navigation
    expect(page).to have_button("Get Started Now") # Hero and Pricing sections
    
    # Verify buttons are present and clickable in specific sections
    within('nav') do
      expect(page).to have_button("Get Started")
    end
    
    within('#pricing') do
      expect(page).to have_button("Get Started Now")
    end
    
    # Verify we have multiple CTA buttons across the page
    expect(all('button', text: /Get Started/).count).to be >= 2
  end
  
  scenario "User can navigate using anchor links" do
    visit root_path
    
    # Test navigation links exist and have proper href attributes
    expect(page).to have_link("Features", href: "#features")
    expect(page).to have_link("How It Works", href: "#how-it-works")
    expect(page).to have_link("Guides", href: "#guides")
    expect(page).to have_link("Pricing", href: "#pricing")
  end
  
  scenario "Page displays proper brand elements and styling" do
    visit root_path
    
    # Check that brand elements are present
    expect(page).to have_text("🌀 GINGGA") # Brand logo
    expect(page).to have_text("🦉") # Noctua emoji
    expect(page).to have_text("🐒") # Sagui emoji
    expect(page).to have_text("🦊") # Voxa emoji
    expect(page).to have_text("🐘") # Alumo emoji
    
    # Check section IDs for proper navigation
    expect(page).to have_css("#features")
    expect(page).to have_css("#how-it-works")
    expect(page).to have_css("#guides")
    expect(page).to have_css("#pricing")
  end
end
