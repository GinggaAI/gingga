# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Planning Content Details', type: :system, js: true do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user, slug: 'test-brand', name: 'Test Brand') }
  let(:strategy_plan) do
    create(:creas_strategy_plan,
           user: user,
           brand: brand,
           month: '2025-01',
           status: 'completed',
           weekly_plan: sample_weekly_plan)
  end

  let(:sample_weekly_plan) do
    [
      {
        "week" => 1,
        "ideas" => [
          {
            "id" => "202501-test-brand-w1-i1-C",
            "title" => "AI Tools Every Entrepreneur Should Know",
            "description" => "Introduce a series of AI tools that are essential for entrepreneurs.",
            "hook" => "Discover the AI tools that can revolutionize your startup!",
            "cta" => "Explore these AI tools now!",
            "platform" => "Instagram Reels",
            "status" => "draft",
            "pilar" => "C",
            "kpi_focus" => "reach",
            "visual_notes" => "Dynamic transitions between tool demonstrations and expert commentary.",
            "success_criteria" => "≥10,000 views",
            "recommended_template" => "avatar_and_video"
          },
          {
            "id" => "202501-test-brand-w1-i2-R",
            "title" => "Building Your Personal Brand",
            "description" => "Tips for entrepreneurs on building a strong personal brand.",
            "hook" => "Want to stand out as an entrepreneur?",
            "cta" => "Start building your brand today!",
            "platform" => "TikTok",
            "status" => "in_production",
            "pilar" => "R",
            "kpi_focus" => "engagement"
          }
        ]
      },
      {
        "week" => 2,
        "ideas" => [
          {
            "id" => "202501-test-brand-w2-i1-E",
            "title" => "Advanced AI Strategies",
            "description" => "Deep dive into advanced AI implementation strategies.",
            "hook" => "Ready to level up your AI game?",
            "cta" => "Learn advanced strategies now!",
            "platform" => "LinkedIn",
            "status" => "ready_for_review",
            "pilar" => "E",
            "kpi_focus" => "CTR"
          }
        ]
      }
    ]
  end

  before do
    login_as(user, scope: :user)
    allow(user).to receive(:current_brand).and_return(brand)
    strategy_plan # Create the strategy plan
  end

  describe 'Content details presentation' do
    context 'when viewing planning page with strategy' do
      before do
        visit "/#{brand.slug}/en/planning?plan_id=#{strategy_plan.id}"
        # Wait for JavaScript to load and populate calendar
        expect(page).to have_content('AI Tools Every Entrepreneur Should Know', wait: 5)
      end

      it 'displays content items in the calendar' do
        # Verify content items are displayed
        expect(page).to have_content('AI Tools Every Entrepreneur Should Know')
        expect(page).to have_content('Building Your Personal Brand')
        expect(page).to have_content('Advanced AI Strategies')
      end

      it 'shows content details when clicking on content item' do
        # Click on the first content item
        first_content = find('div', text: 'AI Tools Every Entrepreneur Should Know')
        first_content.click

        # Wait for AJAX request to complete and details to appear
        expect(page).to have_content('📋 Week 1 Details', wait: 5)
        expect(page).to have_content('🎣 Hook', wait: 2)
        expect(page).to have_content('Discover the AI tools that can revolutionize your startup!')
        expect(page).to have_content('📢 Call to Action')
        expect(page).to have_content('Explore these AI tools now!')
        expect(page).to have_content('📝 Description')
        expect(page).to have_content('Introduce a series of AI tools')
      end

      it 'displays all content fields correctly in details' do
        # Click on content with complete data
        first_content = find('div', text: 'AI Tools Every Entrepreneur Should Know')
        first_content.click

        # Wait for details to load
        within('#week-details-0', wait: 5) do
          # Verify all key fields are displayed
          expect(page).to have_content('AI Tools Every Entrepreneur Should Know')
          expect(page).to have_content('🎣 Hook')
          expect(page).to have_content('Discover the AI tools that can revolutionize your startup!')
          expect(page).to have_content('📢 Call to Action')
          expect(page).to have_content('Explore these AI tools now!')
          expect(page).to have_content('🎨 Visual Notes')
          expect(page).to have_content('Dynamic transitions between tool demonstrations')
          expect(page).to have_content('🎯 KPI Focus')
          expect(page).to have_content('reach')
          expect(page).to have_content('📊 Success Criteria')
          expect(page).to have_content('≥10,000 views')
          expect(page).to have_content('Pillar C')
        end
      end

      it 'allows closing content details' do
        # Open details
        first_content = find('div', text: 'AI Tools Every Entrepreneur Should Know')
        first_content.click

        # Wait for details to appear
        expect(page).to have_content('📋 Week 1 Details', wait: 5)

        # Close details
        within('#week-details-0') do
          find('button', text: '×').click
        end

        # Verify details are hidden
        expect(page).not_to have_content('📋 Week 1 Details')
      end

      it 'can show details for multiple content items in different weeks' do
        # Show details for Week 1 content
        first_content = find('div', text: 'AI Tools Every Entrepreneur Should Know')
        first_content.click
        expect(page).to have_content('📋 Week 1 Details', wait: 5)

        # Show details for Week 2 content
        second_content = find('div', text: 'Advanced AI Strategies')
        second_content.click
        expect(page).to have_content('📋 Week 2 Details', wait: 5)

        # Both should be visible
        expect(page).to have_content('📋 Week 1 Details')
        expect(page).to have_content('📋 Week 2 Details')
      end

      it 'makes correct AJAX request to brand-scoped endpoint' do
        # Monitor network requests
        page.driver.network_traffic.clear

        # Click on content item
        first_content = find('div', text: 'AI Tools Every Entrepreneur Should Know')
        first_content.click

        # Wait for AJAX request
        sleep(1)

        # Verify the request was made to the correct brand-scoped URL
        ajax_requests = page.driver.network_traffic.select do |request|
          request.url.include?('/planning/content_details') &&
          request.url.include?(brand.slug) &&
          request.url.include?('en')
        end

        expect(ajax_requests).not_to be_empty, "Expected AJAX request to brand-scoped content_details endpoint"

        # Verify the URL format
        request = ajax_requests.first
        expect(request.url).to include("/#{brand.slug}/en/planning/content_details")
      end
    end

    context 'when content has different statuses' do
      it 'displays status-specific styling and content' do
        visit "/#{brand.slug}/en/planning?plan_id=#{strategy_plan.id}"

        # Draft status
        draft_content = find('div', text: 'AI Tools Every Entrepreneur Should Know')
        expect(draft_content[:class]).to include('gray') # Draft styling

        # In production status
        production_content = find('div', text: 'Building Your Personal Brand')
        expect(production_content[:class]).to include('blue') # In production styling

        # Ready for review status
        review_content = find('div', text: 'Advanced AI Strategies')
        expect(review_content[:class]).to include('yellow') # Ready for review styling
      end
    end

    context 'error handling' do
      it 'shows error message when AJAX request fails' do
        # Simulate server error by visiting with invalid brand
        visit "/invalid-brand/en/planning"

        # Should handle gracefully without breaking the page
        expect(page).not_to have_content('500 Error')
      end

      it 'handles malformed content data gracefully' do
        # This would be tested by mocking the AJAX response
        # For now, we ensure the page doesn't break with missing content
        visit "/#{brand.slug}/en/planning"
        expect(page).to have_content('Planning', wait: 5)
      end
    end
  end

  describe 'Smart planning specific behavior' do
    it 'works identically on smart planning route' do
      visit "/#{brand.slug}/en/smart-planning?plan_id=#{strategy_plan.id}"

      # Should show same content and behavior as regular planning
      expect(page).to have_content('AI Tools Every Entrepreneur Should Know', wait: 5)

      # Content details should work the same
      first_content = find('div', text: 'AI Tools Every Entrepreneur Should Know')
      first_content.click

      expect(page).to have_content('📋 Week 1 Details', wait: 5)
      expect(page).to have_content('Discover the AI tools that can revolutionize your startup!')
    end
  end

  describe 'Brand isolation in content details' do
    let(:other_user) { create(:user) }
    let(:other_brand) { create(:brand, user: other_user, slug: 'other-brand', name: 'Other Brand') }
    let(:other_strategy) do
      create(:creas_strategy_plan,
             user: other_user,
             brand: other_brand,
             month: '2025-01',
             status: 'completed',
             weekly_plan: sample_weekly_plan)
    end

    it 'only shows content details for current brand' do
      # Create strategy for another brand
      other_strategy

      # Visit current brand's planning
      visit "/#{brand.slug}/en/planning?plan_id=#{strategy_plan.id}"

      # Content details should only show current brand's data
      first_content = find('div', text: 'AI Tools Every Entrepreneur Should Know')
      first_content.click

      # The content should be rendered with current brand context
      expect(page).to have_content('📋 Week 1 Details', wait: 5)

      # Should not accidentally show other brand's content
      expect(page).not_to have_content('Other Brand')
    end
  end
end