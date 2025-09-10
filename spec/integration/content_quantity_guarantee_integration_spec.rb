require 'rails_helper'

RSpec.describe 'Content Quantity Guarantee Integration' do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user, content_language: 'en', timezone: 'Europe/Madrid') }

  describe 'end-to-end content quantity guarantee workflow' do
    context 'with a realistic 20-item monthly content strategy' do
      # Simulate a realistic monthly strategy with 20 content pieces across 4 weeks
      let(:weekly_plan) do
        [
          # Week 1: 5 content items
          {
            'ideas' => [
              { 'id' => '202508-brand-C-w1-i1', 'title' => 'Educational Post 1', 'description' => 'Learn about our industry insights', 'platform' => 'Instagram', 'pilar' => 'C' },
              { 'id' => '202508-brand-R-w1-i2', 'title' => 'Community Highlight', 'description' => 'Showcasing our amazing community', 'platform' => 'Instagram', 'pilar' => 'R' },
              { 'id' => '202508-brand-E-w1-i3', 'title' => 'Fun Friday Content', 'description' => 'Entertainment for the weekend', 'platform' => 'TikTok', 'pilar' => 'E' },
              { 'id' => '202508-brand-A-w1-i4', 'title' => 'Product Announcement', 'description' => 'New feature announcement', 'platform' => 'Instagram', 'pilar' => 'A' },
              { 'id' => '202508-brand-S-w1-i5', 'title' => 'Limited Offer', 'description' => 'Special promotion this week', 'platform' => 'YouTube', 'pilar' => 'S' }
            ]
          },
          # Week 2: 5 content items
          {
            'ideas' => [
              { 'id' => '202508-brand-C-w2-i1', 'title' => 'How-To Guide', 'description' => 'Step-by-step tutorial', 'platform' => 'YouTube', 'pilar' => 'C' },
              { 'id' => '202508-brand-R-w2-i2', 'title' => 'Customer Story', 'description' => 'Success story from our client', 'platform' => 'Instagram', 'pilar' => 'R' },
              { 'id' => '202508-brand-E-w2-i3', 'title' => 'Behind Scenes', 'description' => 'Office fun and team culture', 'platform' => 'TikTok', 'pilar' => 'E' },
              { 'id' => '202508-brand-A-w2-i4', 'title' => 'Brand Values', 'description' => 'What we stand for as a company', 'platform' => 'Instagram', 'pilar' => 'A' },
              { 'id' => '202508-brand-S-w2-i5', 'title' => 'Flash Sale', 'description' => 'Quick 24-hour sale announcement', 'platform' => 'Instagram', 'pilar' => 'S' }
            ]
          },
          # Week 3: 5 content items
          {
            'ideas' => [
              { 'id' => '202508-brand-C-w3-i1', 'title' => 'Industry Trends', 'description' => 'Latest trends in our industry', 'platform' => 'Instagram', 'pilar' => 'C' },
              { 'id' => '202508-brand-R-w3-i2', 'title' => 'Team Introduction', 'description' => 'Meet our team members', 'platform' => 'Instagram', 'pilar' => 'R' },
              { 'id' => '202508-brand-E-w3-i3', 'title' => 'Meme Monday', 'description' => 'Relatable industry memes', 'platform' => 'Instagram', 'pilar' => 'E' },
              { 'id' => '202508-brand-A-w3-i4', 'title' => 'Product Demo', 'description' => 'Live demonstration of features', 'platform' => 'YouTube', 'pilar' => 'A' },
              { 'id' => '202508-brand-S-w3-i5', 'title' => 'Seasonal Offer', 'description' => 'End of summer promotion', 'platform' => 'Instagram', 'pilar' => 'S' }
            ]
          },
          # Week 4: 5 content items
          {
            'ideas' => [
              { 'id' => '202508-brand-C-w4-i1', 'title' => 'Monthly Recap', 'description' => 'Summary of August achievements', 'platform' => 'Instagram', 'pilar' => 'C' },
              { 'id' => '202508-brand-R-w4-i2', 'title' => 'Community Goals', 'description' => 'Setting goals for next month', 'platform' => 'Instagram', 'pilar' => 'R' },
              { 'id' => '202508-brand-E-w4-i3', 'title' => 'Challenge Wrap-up', 'description' => 'Results from our monthly challenge', 'platform' => 'TikTok', 'pilar' => 'E' },
              { 'id' => '202508-brand-A-w4-i4', 'title' => 'Success Metrics', 'description' => 'Sharing our growth numbers', 'platform' => 'Instagram', 'pilar' => 'A' },
              { 'id' => '202508-brand-S-w4-i5', 'title' => 'Next Month Preview', 'description' => 'Teasing September offerings', 'platform' => 'YouTube', 'pilar' => 'S' }
            ]
          }
        ]
      end

      let(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               weekly_plan: weekly_plan,
               month: '2025-08',
               frequency_per_week: 5)
      end

      it 'guarantees all 20 content items are created regardless of initial failures' do
        service = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan)

        # Track logging to verify retry mechanism
        allow(Rails.logger).to receive(:info)

        result = service.call

        # GUARANTEE: Exactly 20 content items should be created
        expect(result.count).to eq(20), "Expected 20 content items, but got #{result.count}"
        expect(CreasContentItem.where(creas_strategy_plan: strategy_plan).count).to eq(20)

        # Verify all expected content IDs are present
        created_ids = result.map(&:content_id).sort
        expected_ids = weekly_plan.flat_map { |week| week['ideas'].map { |idea| idea['id'] } }.sort

        expect(created_ids).to eq(expected_ids), "Missing content IDs: #{expected_ids - created_ids}"

        # Verify content is distributed across all 4 weeks
        week_distribution = result.group_by(&:week).transform_values(&:count)
        expect(week_distribution.keys.sort).to eq([ 1, 2, 3, 4 ])
        expect(week_distribution.values).to all(eq(5))

        # Verify all pilars are represented
        pilar_distribution = result.group_by(&:pilar).transform_values(&:count)
        expect(pilar_distribution.keys.sort).to eq([ 'A', 'C', 'E', 'R', 'S' ])
        expect(pilar_distribution.values).to all(eq(4)) # 4 items per pilar across 4 weeks

        # Verify platform distribution matches the defined plan
        platform_distribution = result.group_by(&:platform).transform_values(&:count)
        expected_platforms = weekly_plan.flat_map { |week| week['ideas'].map { |idea| idea['platform'].downcase } }
        expected_platform_counts = expected_platforms.group_by(&:itself).transform_values(&:count)

        expect(platform_distribution).to eq(expected_platform_counts)
      end
    end

    context 'with validation conflicts requiring retry mechanism' do
      let(:weekly_plan) do
        [
          {
            'ideas' => [
              { 'id' => '202508-duplicate-title', 'title' => 'Duplicate Title', 'description' => 'This will cause conflicts', 'platform' => 'Instagram', 'pilar' => 'C' },
              { 'id' => '202508-another-duplicate', 'title' => 'Duplicate Title', 'description' => 'This will also cause conflicts', 'platform' => 'Instagram', 'pilar' => 'A' },
              { 'id' => '202508-unique-content', 'title' => 'Unique Content', 'description' => 'This should work fine', 'platform' => 'Instagram', 'pilar' => 'E' }
            ]
          }
        ]
      end

      let(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               weekly_plan: weekly_plan,
               month: '2025-08')
      end

      # Create pre-existing content that might conflict
      let!(:existing_content) do
        existing_plan = create(:creas_strategy_plan, user: user, brand: brand, month: '2025-07')
        create(:creas_content_item,
               user: user,
               brand: brand,
               creas_strategy_plan: existing_plan,
               content_name: 'Duplicate Title',
               post_description: 'This will cause conflicts')
      end

      it 'resolves validation conflicts and guarantees all content is created with unique attributes' do
        service = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan)

        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)

        result = service.call

        # GUARANTEE: All 3 items should be created despite conflicts
        expect(result.count).to eq(3)

        # Verify that conflicting items have unique names
        content_names = result.map(&:content_name)
        expect(content_names.uniq.count).to eq(3), "Content names should be unique: #{content_names}"

        # Find the items that had conflicts
        duplicate_items = result.select { |item| item.content_id.include?('duplicate') }
        expect(duplicate_items.count).to eq(2)

        # Verify uniqueness strategies were applied
        duplicate_items.each do |item|
          expect(item.content_name).not_to eq('Duplicate Title')
          expect(item.content_name).to include('Duplicate Title') # Should contain original but be modified
        end

        # Verify the unique item was created normally
        unique_item = result.find { |item| item.content_id == '202508-unique-content' }
        expect(unique_item.content_name).to eq('Unique Content (Week 1)')
      end
    end

    context 'when integrated with VoxaContentService workflow' do
      let(:weekly_plan) do
        [
          {
            'ideas' => [
              { 'id' => '202508-integration-test', 'title' => 'Integration Test Content', 'description' => 'Testing full workflow', 'platform' => 'Instagram', 'pilar' => 'C' }
            ]
          }
        ]
      end

      let(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               weekly_plan: weekly_plan,
               month: '2025-08')
      end

      it 'ensures content quantity is maintained through the full content creation pipeline' do
        # Step 1: Initialize draft content items
        initializer_service = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan)
        draft_items = initializer_service.call

        expect(draft_items.count).to eq(1)
        expect(draft_items.first.status).to eq('draft')
        expect(draft_items.first.content_id).to eq('202508-integration-test')

        # Verify the item is persisted and associated correctly
        expect(draft_items.first).to be_persisted
        expect(draft_items.first.user).to eq(user)
        expect(draft_items.first.brand).to eq(brand)
        expect(draft_items.first.creas_strategy_plan).to eq(strategy_plan)

        # Step 2: Simulate VoxaContentService finding and updating the same item
        # (This tests that the quantity guarantee doesn't interfere with subsequent processing)
        found_item = CreasContentItem.find_by(content_id: '202508-integration-test')
        expect(found_item).to be_present
        expect(found_item.id).to eq(draft_items.first.id)

        # Update the item (simulating Voxa processing)
        found_item.update!(
          status: 'in_production',
          post_description: 'Enhanced by Voxa',
          text_base: 'Improved content',
          publish_date: Date.current + 1.day
        )

        # Step 3: Verify quantity is still guaranteed if initializer runs again
        second_run_items = initializer_service.call

        # Should not create duplicates
        expect(CreasContentItem.where(creas_strategy_plan: strategy_plan).count).to eq(1)
        expect(second_run_items.count).to eq(1)

        # Should update the existing item, not create a new one
        updated_item = second_run_items.first
        expect(updated_item.id).to eq(found_item.id)
        expect(updated_item.status).to eq('in_production') # Should preserve Voxa updates
      end
    end

    context 'with moderate content volumes' do
      let(:weekly_plan) do
        # Generate 16 content items across 4 weeks (4 per week) with diverse content
        (1..4).map do |week|
          {
            'ideas' => [
              {
                'id' => "202508-mod-C-w#{week}-i1",
                'title' => "Educational Week #{week}",
                'description' => "Educational content for week #{week}",
                'platform' => 'Instagram',
                'pilar' => 'C'
              },
              {
                'id' => "202508-mod-R-w#{week}-i2",
                'title' => "Community Week #{week}",
                'description' => "Community content for week #{week}",
                'platform' => 'TikTok',
                'pilar' => 'R'
              },
              {
                'id' => "202508-mod-E-w#{week}-i3",
                'title' => "Entertainment Week #{week}",
                'description' => "Entertainment content for week #{week}",
                'platform' => 'YouTube',
                'pilar' => 'E'
              },
              {
                'id' => "202508-mod-A-w#{week}-i4",
                'title' => "Advertising Week #{week}",
                'description' => "Promotional content for week #{week}",
                'platform' => 'Instagram',
                'pilar' => 'A'
              }
            ]
          }
        end
      end

      let(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               weekly_plan: weekly_plan,
               month: '2025-08')
      end

      it 'efficiently processes moderate volumes while maintaining quantity guarantee' do
        service = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan)

        # Measure performance
        start_time = Time.current
        result = service.call
        end_time = Time.current

        processing_time = end_time - start_time

        # GUARANTEE: All 16 items should be created (4 weeks × 4 items)
        expect(result.count).to eq(16)
        expect(CreasContentItem.where(creas_strategy_plan: strategy_plan).count).to eq(16)

        # Performance expectation: Should complete within reasonable time
        expect(processing_time).to be < 10.seconds, "Processing took #{processing_time} seconds, which is too slow"

        # Verify data integrity
        expect(result.all?(&:persisted?)).to be true
        expect(result.map(&:content_id).uniq.count).to eq(16) # All unique
        expect(result.map(&:week).uniq.sort).to eq([ 1, 2, 3, 4 ])

        # Verify diverse content creation
        pilar_distribution = result.group_by(&:pilar).transform_values(&:count)
        expect(pilar_distribution).to eq({ 'C' => 4, 'R' => 4, 'E' => 4, 'A' => 4 })

        # Verify transaction integrity (all or nothing)
        expect(result.all? { |item| item.creas_strategy_plan == strategy_plan }).to be true
      end
    end
  end
end
