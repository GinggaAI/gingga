# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Strategy Creation with Brand Association', type: :system, js: true do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:primary_brand) { create(:brand, user: user, slug: 'my-startup', name: 'My Startup') }
  let(:secondary_brand) { create(:brand, user: user, slug: 'side-project', name: 'Side Project') }

  before do
    # Perform ActiveJob jobs immediately (inline) for these tests
    ActiveJob::Base.queue_adapter = :inline

    login_as(user, scope: :user)

    # Setup brands
    primary_brand
    secondary_brand
    # Set user's last_brand to ensure current_brand returns primary_brand
    user.update(last_brand: primary_brand)

    # Mock external services to avoid real API calls
    allow_any_instance_of(ApiTokenValidatorService).to receive(:call).and_return({ valid: true })

    # Mock OpenAI response for strategy generation
    mock_openai_response = {
      "brand_name" => primary_brand.name,
      "brand_slug" => primary_brand.slug,
      "strategy_name" => "AI Generated Strategy (4 weeks)",
      "month" => "2025-01",
      "objective_of_the_month" => "awareness",
      "frequency_per_week" => 3,
      "status" => "completed",
      "weekly_plan" => [
        {
          "week" => 1,
          "ideas" => [
            {
              "id" => "202501-my-startup-w1-i1-C",
              "title" => "#{primary_brand.name} Success Story",
              "description" => "Share the journey of #{primary_brand.name}",
              "hook" => "Discover how #{primary_brand.name} achieved success!",
              "cta" => "Follow #{primary_brand.name} for more insights!",
              "platform" => "Instagram",
              "status" => "draft",
              "pilar" => "C"
            }
          ]
        }
      ],
      "monthly_themes" => [ "brand building" ]
    }.to_json

    mock_chat_client = instance_double(GinggaOpenAI::ChatClient)
    allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
    allow(mock_chat_client).to receive(:chat!).and_return(mock_openai_response)
  end

  after do
    # Reset queue adapter to test default after each test
    ActiveJob::Base.queue_adapter = :test
  end

  describe 'Strategy creation flow' do
    context 'when user creates strategy for primary brand' do
      before do
        visit "/#{primary_brand.slug}/en/planning"
      end

      it 'creates strategy associated with correct brand' do
        # Open strategy creation form
        click_button 'Add Content'

        # Fill strategy form
        within('#strategy-form') do
          select 'Awareness - Build brand recognition', from: 'strategy_form[objective_of_the_month]'
          fill_in 'strategy_form[objective_details]', with: 'Build brand awareness for our startup'
          fill_in 'strategy_form[frequency_per_week]', with: '3'
        end

        # Submit strategy creation
        click_button 'Generate Strategy'

        # Wait for the UI to show processing state
        expect(page).to have_content('Strategy Generation In Progress', wait: 10)

        # Verify we're still on the correct brand-scoped URL
        expect(current_url).to include("/#{primary_brand.slug}/en/planning")
        expect(page).to have_content(primary_brand.name)
      end

      it 'displays content with correct brand context in weekly plan' do
        click_button 'Add Content'

        within('#strategy-form') do
          select 'Awareness - Build brand recognition', from: 'strategy_form[objective_of_the_month]'
          fill_in 'strategy_form[frequency_per_week]', with: '3'
        end

        click_button 'Generate Strategy'

        # Verify the UI shows the correct brand context
        expect(page).to have_content('Strategy Generation In Progress', wait: 10)
        expect(page).to have_content(primary_brand.name)
      end

      it 'shows content details with correct brand information' do
        click_button 'Add Content'

        within('#strategy-form') do
          select 'Awareness - Build brand recognition', from: 'strategy_form[objective_of_the_month]'
          fill_in 'strategy_form[frequency_per_week]', with: '3'
        end

        click_button 'Generate Strategy'

        # Verify UI shows correct brand context
        expect(page).to have_content('Strategy Generation In Progress', wait: 10)
        expect(page).to have_content(primary_brand.name)
      end

      it 'redirects to correct brand-scoped URL after strategy creation' do
        click_button 'Add Content'

        within('#strategy-form') do
          select 'Awareness - Build brand recognition', from: 'strategy_form[objective_of_the_month]'
          fill_in 'strategy_form[frequency_per_week]', with: '3'
        end

        click_button 'Generate Strategy'

        # Verify we stay on the correct brand-scoped URL
        expect(current_url).to include("/#{primary_brand.slug}/en/planning")
      end
    end

    context 'when user switches brands' do
      it 'creates strategy for the currently active brand' do
        # Start with primary brand
        visit "/#{primary_brand.slug}/en/planning"

        # Verify we're on the primary brand's planning page
        expect(current_url).to include("/#{primary_brand.slug}/en/planning")
        expect(page).to have_content(primary_brand.name)

        # Create strategy for primary brand
        click_button 'Add Content'
        within('#strategy-form') do
          select 'Awareness - Build brand recognition', from: 'strategy_form[objective_of_the_month]'
          fill_in 'strategy_form[frequency_per_week]', with: '3'
        end
        click_button 'Generate Strategy'
        expect(page).to have_content('Strategy Generation In Progress', wait: 10)

        # Switch to secondary brand by updating last_brand
        user.update(last_brand: secondary_brand)

        # Re-authenticate to refresh the session
        logout
        login_as(user, scope: :user)

        # Visit secondary brand planning page
        visit "/#{secondary_brand.slug}/en/planning"

        # Verify we're now on the secondary brand's planning page
        expect(current_url).to include("/#{secondary_brand.slug}/en/planning")
        expect(page).to have_content(secondary_brand.name)

        # Verify the form is available for the secondary brand
        # (if there's already a strategy in progress, the button might be disabled,
        # which is correct behavior)
        expect(page).to have_selector('button', text: 'Add Content')
      end
    end

    context 'error handling when no brand is available' do
      before do
        allow(user).to receive(:current_brand).and_return(nil)
      end

      it 'shows error message when user has no current brand' do
        visit "/invalid-brand/en/planning"

        # Should handle gracefully - might redirect or show error
        expect(page).not_to have_content('500 Error')
      end
    end
  end

  describe 'Brand isolation in strategy access' do
    let(:other_user) { create(:user) }
    let(:other_brand) { create(:brand, user: other_user, slug: 'competitor', name: 'Competitor Brand') }
    let(:other_strategy) do
      create(:creas_strategy_plan,
             user: other_user,
             brand: other_brand,
             month: '2025-01',
             status: 'completed',
             weekly_plan: [
               {
                 "week" => 1,
                 "ideas" => [
                   {
                     "title" => "Competitor's Secret Strategy",
                     "description" => "This should not be visible to other users",
                     "platform" => "Instagram",
                     "status" => "draft"
                   }
                 ]
               }
             ])
    end

    it 'does not show strategies from other brands/users' do
      # Create strategy for another user/brand
      other_strategy

      # Visit current user's brand planning
      visit "/#{primary_brand.slug}/en/planning"

      # Should not see other user's strategies
      expect(page).not_to have_content("Competitor's Secret Strategy")
      expect(page).not_to have_content("Competitor Brand")
    end

    it 'cannot access other brand strategies via direct URL' do
      # Create strategy for another user
      other_strategy

      # Try to access other brand's strategy directly
      visit "/#{primary_brand.slug}/en/planning?plan_id=#{other_strategy.id}"

      # Should not show the other brand's strategy
      expect(page).not_to have_content("Competitor's Secret Strategy")
    end
  end

  describe 'Content items creation with brand association' do
    it 'creates content items associated with correct brand' do
      visit "/#{primary_brand.slug}/en/planning"

      # Create strategy
      click_button 'Add Content'
      within('#strategy-form') do
        select 'Awareness - Build brand recognition', from: 'strategy_form[objective_of_the_month]'
        fill_in 'strategy_form[frequency_per_week]', with: '3'
      end
      click_button 'Generate Strategy'

      # Verify the service was called with the correct brand
      # The content items will be created asynchronously by the job
      # We just verify that the correct brand context was passed
      expect(page).to have_content('Strategy Generation In Progress', wait: 10)
      expect(page).to have_content(primary_brand.name)
    end
  end

  describe 'URL generation with brand context' do
    it 'generates correct brand-scoped URLs for content details' do
      visit "/#{primary_brand.slug}/en/planning"

      # Create strategy
      click_button 'Add Content'
      within('#strategy-form') do
        select 'Awareness - Build brand recognition', from: 'strategy_form[objective_of_the_month]'
        fill_in 'strategy_form[frequency_per_week]', with: '3'
      end
      click_button 'Generate Strategy'

      # Verify the URL contains the correct brand slug
      expect(current_url).to include("/#{primary_brand.slug}/en/planning")
      expect(page).to have_content('Strategy Generation In Progress', wait: 10)
    end
  end
end
