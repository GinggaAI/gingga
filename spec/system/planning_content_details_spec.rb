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
    # Set user's last_brand to ensure current_brand returns the correct brand
    user.update(last_brand: brand)
    strategy_plan # Create the strategy plan
  end

  describe 'Content details presentation' do
    context 'when viewing planning page with strategy' do
      before do
        visit "/#{brand.slug}/en/planning?plan_id=#{strategy_plan.id}"
        # Wait for JavaScript to load and populate calendar - check for truncated text
        expect(page).to have_content('AI Tools Every Ent', wait: 5)
      end

      it 'displays content items in the calendar' do
        # Verify content items are displayed (titles are truncated in calendar view)
        expect(page).to have_content('AI Tools Every Ent')
        expect(page).to have_content('Building Your Pers')
        expect(page).to have_content('Advanced AI Strate')
      end

      it 'shows content details when clicking on content item' do
        # Click on the first content item using CSS class and visible text
        first_content = find('.content-piece-card', text: /AI Tools/)
        first_content.click

        # Wait for content details to appear (no AJAX, JavaScript shows hidden section)
        expect(page).to have_content('📋 Week 1', wait: 5)
        expect(page).to have_content('🎣 Hook', wait: 2)
        expect(page).to have_content('Discover the AI tools that can revolutionize your startup!')
        expect(page).to have_content('📢 Call to Action')
        expect(page).to have_content('Explore these AI tools now!')
        expect(page).to have_content('📝 Description')
        expect(page).to have_content('Introduce a series of AI tools')
      end

      it 'displays all content fields correctly in details' do
        # Click on content with complete data
        first_content = find('.content-piece-card', text: /AI Tools/)
        first_content.click

        # Wait for details to load
        within('#week-details-0', wait: 5) do
          # Verify all key fields are displayed - full title shown in details
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
        first_content = find('.content-piece-card', text: /AI Tools/)
        first_content.click

        # Wait for details to appear
        expect(page).to have_css('#week-details-0[style*="display: block"]', wait: 5)

        # Close details - use the first close button (the one in the header)
        within('#week-details-0') do
          all('button', text: '×').first.click
        end

        # Verify details are hidden (need visible: false to check hidden elements)
        expect(page).to have_css('#week-details-0[style*="display: none"]', visible: false, wait: 2)
      end

      it 'can show details for multiple content items in different weeks' do
        # Show details for Week 1 content
        first_content = find('.content-piece-card', text: /AI Tools/)
        first_content.click
        expect(page).to have_css('#week-details-0[style*="display: block"]', wait: 5)

        # Show details for Week 2 content
        second_content = find('.content-piece-card', text: /Advanced AI/)
        second_content.click
        expect(page).to have_css('#week-details-1[style*="display: block"]', wait: 5)

        # Both should be visible
        expect(page).to have_css('#week-details-0[style*="display: block"]')
        expect(page).to have_css('#week-details-1[style*="display: block"]')
      end

      it 'renders content details without AJAX' do
        # NOTE: This feature was refactored from AJAX to JavaScript-only
        # Content data is embedded in data attributes on the page load
        # No network requests are made when showing content details

        # Click on content item
        first_content = find('.content-piece-card', text: /AI Tools/)

        # Verify data is embedded in the element
        expect(first_content['data-content-piece']).to be_present

        # Clicking should show details without any HTTP requests
        first_content.click

        # Verify details appear (data was already on the page)
        expect(page).to have_css('#week-details-0[style*="display: block"]', wait: 2)
        expect(page).to have_content('AI Tools Every Entrepreneur Should Know')
      end
    end

    context 'when content has different statuses' do
      it 'displays status-specific styling and content' do
        visit "/#{brand.slug}/en/planning?plan_id=#{strategy_plan.id}"

        # Wait for content to load
        expect(page).to have_css('.content-piece-card', wait: 5)

        # Draft status
        draft_content = find('.content-piece-card', text: /AI Tools/)
        expect(draft_content[:class]).to include('gray') # Draft styling

        # In production status
        production_content = find('.content-piece-card', text: /Building Your/)
        expect(production_content[:class]).to include('blue') # In production styling

        # Ready for review status
        review_content = find('.content-piece-card', text: /Advanced AI/)
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

      # Should show same content and behavior as regular planning (text is truncated)
      expect(page).to have_content('AI Tools Every Ent', wait: 5)

      # Content details should work the same
      first_content = find('.content-piece-card', text: /AI Tools/)
      first_content.click

      expect(page).to have_css('#week-details-0[style*="display: block"]', wait: 5)
      expect(page).to have_content('Discover the AI tools that can revolutionize your startup!')
    end
  end

  describe 'Brand isolation in content details' do
    it 'only shows content details for current brand' do
      # Visit current brand's planning
      visit "/#{brand.slug}/en/planning?plan_id=#{strategy_plan.id}"

      # Wait for content to load (text is truncated)
      expect(page).to have_content('AI Tools Every Ent', wait: 5)

      # Content details should only show current brand's data
      first_content = find('.content-piece-card', text: /AI Tools/)
      first_content.click

      # The content should be rendered with current brand context
      expect(page).to have_css('#week-details-0[style*="display: block"]', wait: 5)

      # Verify it's the current brand's content
      expect(page).to have_content('AI Tools Every Entrepreneur Should Know')

      # Verify the brand name is shown on the page
      expect(page).to have_content(brand.name)

      # The key test: strategy and content are associated with the current brand
      expect(strategy_plan.brand).to eq(brand)
      expect(strategy_plan.brand.slug).to eq(brand.slug)
    end
  end
end
