# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Strategy Creation with Brand Association', type: :system, js: true do
  let(:user) { create(:user) }
  let(:primary_brand) { create(:brand, user: user, slug: 'my-startup', name: 'My Startup') }
  let(:secondary_brand) { create(:brand, user: user, slug: 'side-project', name: 'Side Project') }

  before do
    login_as(user, scope: :user)

    # Setup brands
    primary_brand
    secondary_brand
    allow(user).to receive(:current_brand).and_return(primary_brand)

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
      "monthly_themes" => ["brand building"]
    }.to_json

    mock_chat_client = instance_double(GinggaOpenAI::ChatClient)
    allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
    allow(mock_chat_client).to receive(:chat!).and_return(mock_openai_response)
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
          select 'awareness', from: 'strategy_form[objective_of_the_month]'
          fill_in 'strategy_form[objective_details]', with: 'Build brand awareness for our startup'
          fill_in 'strategy_form[frequency_per_week]', with: '3'
        end

        # Submit strategy creation
        expect {
          click_button 'Generate Strategy'
          # Wait for AJAX completion and strategy creation
          expect(page).to have_content('Strategy being created', wait: 10)
        }.to change(CreasStrategyPlan, :count).by(1)

        # Verify strategy is associated with correct brand
        created_strategy = CreasStrategyPlan.last
        expect(created_strategy.brand).to eq(primary_brand)
        expect(created_strategy.user).to eq(user)
      end

      it 'displays content with correct brand context in weekly plan' do
        # Create strategy first
        click_button 'Add Content'

        within('#strategy-form') do
          select 'awareness', from: 'strategy_form[objective_of_the_month]'
          fill_in 'strategy_form[frequency_per_week]', with: '3'
        end

        click_button 'Generate Strategy'
        expect(page).to have_content('Strategy being created', wait: 10)

        # Wait for strategy to be completed and page to update
        expect(page).to have_content(primary_brand.name, wait: 15)

        # Verify content shows correct brand name
        expect(page).to have_content("#{primary_brand.name} Success Story")
        expect(page).not_to have_content("New Brand")
        expect(page).not_to have_content("brand-1")
      end

      it 'shows content details with correct brand information' do
        # Create strategy and wait for completion
        click_button 'Add Content'

        within('#strategy-form') do
          select 'awareness', from: 'strategy_form[objective_of_the_month]'
          fill_in 'strategy_form[frequency_per_week]', with: '3'
        end

        click_button 'Generate Strategy'
        expect(page).to have_content('Strategy being created', wait: 10)

        # Wait for content to appear
        expect(page).to have_content("#{primary_brand.name} Success Story", wait: 15)

        # Click on content to show details
        content_item = find('div', text: "#{primary_brand.name} Success Story")
        content_item.click

        # Verify content details show correct brand information
        within('#week-details-0', wait: 5) do
          expect(page).to have_content("#{primary_brand.name} Success Story")
          expect(page).to have_content("Share the journey of #{primary_brand.name}")
          expect(page).to have_content("Discover how #{primary_brand.name} achieved success!")
          expect(page).to have_content("Follow #{primary_brand.name} for more insights!")

          # Should not contain wrong brand references
          expect(page).not_to have_content("New Brand")
          expect(page).not_to have_content("brand-1")
        end
      end

      it 'redirects to correct brand-scoped URL after strategy creation' do
        click_button 'Add Content'

        within('#strategy-form') do
          select 'awareness', from: 'strategy_form[objective_of_the_month]'
          fill_in 'strategy_form[frequency_per_week]', with: '3'
        end

        click_button 'Generate Strategy'

        # Wait for redirect after strategy creation
        sleep(2)

        # Should still be on the correct brand-scoped URL
        expect(current_url).to include("/#{primary_brand.slug}/en/planning")
        expect(current_url).to include("plan_id=")
      end
    end

    context 'when user switches brands' do
      it 'creates strategy for the currently active brand' do
        # Start with primary brand
        visit "/#{primary_brand.slug}/en/planning"

        # Create strategy for primary brand
        click_button 'Add Content'
        within('#strategy-form') do
          select 'awareness', from: 'strategy_form[objective_of_the_month]'
          fill_in 'strategy_form[frequency_per_week]', with: '3'
        end
        click_button 'Generate Strategy'
        expect(page).to have_content('Strategy being created', wait: 10)

        primary_strategy = CreasStrategyPlan.last

        # Switch to secondary brand (simulate brand switching)
        allow(user).to receive(:current_brand).and_return(secondary_brand)

        # Mock OpenAI response for secondary brand
        secondary_mock_response = {
          "brand_name" => secondary_brand.name,
          "brand_slug" => secondary_brand.slug,
          "strategy_name" => "AI Generated Strategy (4 weeks)",
          "month" => "2025-02",
          "objective_of_the_month" => "engagement",
          "frequency_per_week" => 2,
          "status" => "completed",
          "weekly_plan" => [
            {
              "week" => 1,
              "ideas" => [
                {
                  "title" => "#{secondary_brand.name} Updates",
                  "description" => "Latest from #{secondary_brand.name}",
                  "platform" => "TikTok",
                  "status" => "draft"
                }
              ]
            }
          ]
        }.to_json

        mock_chat_client = instance_double(GinggaOpenAI::ChatClient)
        allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
        allow(mock_chat_client).to receive(:chat!).and_return(secondary_mock_response)

        # Visit secondary brand planning page
        visit "/#{secondary_brand.slug}/en/planning"

        # Create strategy for secondary brand
        click_button 'Add Content'
        within('#strategy-form') do
          select 'engagement', from: 'strategy_form[objective_of_the_month]'
          fill_in 'strategy_form[frequency_per_week]', with: '2'
        end
        click_button 'Generate Strategy'

        # Verify both strategies exist with correct brand associations
        strategies = CreasStrategyPlan.last(2)
        expect(strategies.first.brand).to eq(primary_brand)
        expect(strategies.last.brand).to eq(secondary_brand)
        expect(strategies.first.brand).not_to eq(strategies.last.brand)
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

      # Mock content item creation during strategy generation
      allow_any_instance_of(GenerateNoctuaStrategyBatchJob).to receive(:perform) do |job, plan_id|
        plan = CreasStrategyPlan.find(plan_id)

        # Create content items as part of strategy generation
        create(:creas_content_item,
               creas_strategy_plan: plan,
               user: plan.user,
               brand: plan.brand,
               content_name: "Test Content for #{plan.brand.name}",
               week: 1)
      end

      # Create strategy
      click_button 'Add Content'
      within('#strategy-form') do
        select 'awareness', from: 'strategy_form[objective_of_the_month]'
        fill_in 'strategy_form[frequency_per_week]', with: '3'
      end
      click_button 'Generate Strategy'

      # Wait for strategy creation
      expect(page).to have_content('Strategy being created', wait: 10)

      # Verify content items are associated with correct brand
      created_strategy = CreasStrategyPlan.last
      content_items = created_strategy.creas_content_items

      expect(content_items).not_to be_empty
      content_items.each do |item|
        expect(item.brand).to eq(primary_brand)
        expect(item.user).to eq(user)
        expect(item.content_name).to include(primary_brand.name)
      end
    end
  end

  describe 'URL generation with brand context' do
    it 'generates correct brand-scoped URLs for content details' do
      visit "/#{primary_brand.slug}/en/planning"

      # Create strategy first
      click_button 'Add Content'
      within('#strategy-form') do
        select 'awareness', from: 'strategy_form[objective_of_the_month]'
        fill_in 'strategy_form[frequency_per_week]', with: '3'
      end
      click_button 'Generate Strategy'

      # Wait for content to load
      expect(page).to have_content("#{primary_brand.name} Success Story", wait: 15)

      # Monitor network requests
      page.driver.network_traffic.clear

      # Click on content to trigger AJAX request
      content_item = find('div', text: "#{primary_brand.name} Success Story")
      content_item.click

      # Wait for AJAX request
      sleep(1)

      # Verify AJAX request uses correct brand-scoped URL
      ajax_requests = page.driver.network_traffic.select do |request|
        request.url.include?('/planning/content_details')
      end

      expect(ajax_requests).not_to be_empty

      request_url = ajax_requests.first.url
      expect(request_url).to include("/#{primary_brand.slug}/en/planning/content_details")
      expect(request_url).not_to include('/planning/content_details') # Should not be non-scoped
    end
  end
end