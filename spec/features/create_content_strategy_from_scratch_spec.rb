require 'rails_helper'

# TODO: Add timecop to set the current date to August 1st

RSpec.feature "Create a new content strategy from scratch", type: :feature do
  scenario "The database is empty and the user wants to create a new content strategy" do
    visit root_path
    expect(page).to have_text("Gingga")

    click_on "Create Brand"
    expect(current_path).to eq(new_brand_path)
    fill_in "Brand Name", with: "My awesome brand"
    fill_in "Who is your audience", with: "Mostly young adults who practice sports"
    fill_in "What do you sell or offer?", with: "T-shirts"
    fill_in "Brand Purpose or Mission", with: "Be the number 1 provider of sport t-shirts in the world"
    click_on "Save profile"

    brand = Brand.last
    expect(brand.name).to eq("My awesome brand")

    # To be implemented as multistep form (Wizard)
    # Step 1. Logos
    expect(current_path).to eq(brand_profile_path(brand, :logos))
    within("#logo-0") do
      attach_file "logo[file]", Rails.root.join("spec/fixtures/files/test-logo.svg")
    end
    click_on "Save and continue"
    brand.reload
    expect(brand.logos.last.file).to be_attached
    expect(brand.logos.last.file.filename.to_s).to  eq("test-logo.svg")

    # Step 2. Colors
    expect(current_path).to eq(brand_profile_path(brand, :colors))
    click_on "Save and continue"

    # Step 3. Fonts
    expect(current_path).to eq(brand_profile_path(brand, :fonts))
    click_on "Save and continue"

    # Step 4. Voice
    expect(current_path).to eq(brand_profile_path(brand, :voice))
    click_on "Save and finish"

    expect(current_path).to eq(brand_path(brand))

    # Creating the content strategy
    click_on "Smart Planning"
    expect(page).to have_content("August 1, 2025") # Current month
    expect(page).to have_content("Week 1")
    expect(page).to have_content("Week 2")
    expect(page).to have_content("Week 3")
    expect(page).to have_content("Week 4")
    
  end
end
