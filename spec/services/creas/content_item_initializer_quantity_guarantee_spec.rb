require 'rails_helper'

RSpec.describe Creas::ContentItemInitializerService, 'Quantity Guarantee' do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user, content_language: 'en', timezone: 'Europe/Madrid') }
  
  describe 'content quantity guarantee mechanism' do
    context 'when all content items are created successfully' do
      let(:weekly_plan) do
        [
          {
            'ideas' => [
              { 'id' => '202508-test-C-w1-i1', 'title' => 'Week 1 Content 1', 'platform' => 'Instagram', 'pilar' => 'C' },
              { 'id' => '202508-test-A-w1-i2', 'title' => 'Week 1 Content 2', 'platform' => 'TikTok', 'pilar' => 'A' }
            ]
          },
          {
            'ideas' => [
              { 'id' => '202508-test-E-w2-i1', 'title' => 'Week 2 Content 1', 'platform' => 'Instagram', 'pilar' => 'E' },
              { 'id' => '202508-test-R-w2-i2', 'title' => 'Week 2 Content 2', 'platform' => 'YouTube', 'pilar' => 'R' },
              { 'id' => '202508-test-S-w2-i3', 'title' => 'Week 2 Content 3', 'platform' => 'Instagram', 'pilar' => 'S' }
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
      
      let(:service) { described_class.new(strategy_plan: strategy_plan) }

      it 'creates all expected content items without retries' do
        # Stub logger to track retry attempts
        allow(Rails.logger).to receive(:info)
        
        result = service.call
        
        # Should create exactly 5 content items (2 + 3 from weekly_plan)
        expect(result.count).to eq(5)
        expect(CreasContentItem.count).to eq(5)
        
        # Verify all expected content_ids are created
        created_ids = result.map(&:content_id).sort
        expected_ids = [
          '202508-test-C-w1-i1',
          '202508-test-A-w1-i2', 
          '202508-test-E-w2-i1',
          '202508-test-R-w2-i2',
          '202508-test-S-w2-i3'
        ].sort
        
        expect(created_ids).to eq(expected_ids)
        
        # Should log the final count
        expect(Rails.logger).to have_received(:info).with("ContentItemInitializerService: Final count 5/5 items")
        
        # Should NOT log retry attempts since all items were created successfully
        expect(Rails.logger).not_to have_received(:info).with(/Created \d+\/\d+ items\. Retrying missing content/)
      end
    end

    context 'when some content items fail to create initially' do
      let(:weekly_plan) do
        [
          {
            'ideas' => [
              { 'id' => '202508-test-C-w1-i1', 'title' => 'Week 1 Content 1', 'platform' => 'Instagram', 'pilar' => 'C' },
              { 'id' => '202508-test-A-w1-i2', 'title' => 'Week 1 Content 2', 'platform' => 'TikTok', 'pilar' => 'A' },
              { 'id' => '202508-test-failing-item', 'title' => 'Failing Content', 'platform' => 'Instagram', 'pilar' => 'E' }
            ]
          },
          {
            'ideas' => [
              { 'id' => '202508-test-R-w2-i1', 'title' => 'Week 2 Content 1', 'platform' => 'YouTube', 'pilar' => 'R' }
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
      
      let(:service) { described_class.new(strategy_plan: strategy_plan) }

      before do
        # Mock the first creation attempt to fail for one specific item
        original_method = service.method(:create_content_item_from_idea)
        
        allow(service).to receive(:create_content_item_from_idea) do |idea, pilar|
          if idea['id'] == '202508-test-failing-item'
            # Return an unpersisted item to simulate failure
            item = CreasContentItem.new(content_id: idea['id'])
            # Simulate validation failure
            item.errors.add(:content_name, 'simulated failure')
            item
          else
            # Call the original method for other items
            original_method.call(idea, pilar)
          end
        end
      end

      it 'detects missing content and retries creation with enhanced uniqueness' do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)
        
        result = service.call
        
        # Expected: 4 items total, 3 created initially, 1 retried successfully  
        # (The failing item should be retried and succeed with enhanced uniqueness)
        expect(result.count).to eq(4)
        
        # Should log the retry attempt
        expect(Rails.logger).to have_received(:info).with(/Created \d+\/4 items\. Retrying missing content/)
        expect(Rails.logger).to have_received(:info).with("ContentItemInitializerService: Final count 4/4 items")
        
        # Verify all content IDs are present
        created_ids = result.map(&:content_id).sort
        expected_ids = [
          '202508-test-C-w1-i1',
          '202508-test-A-w1-i2',
          '202508-test-failing-item',
          '202508-test-R-w2-i1'
        ].sort
        
        expect(created_ids).to eq(expected_ids)
      end
    end

    context 'when multiple retry attempts are needed' do
      let(:weekly_plan) do
        [
          {
            'ideas' => [
              { 'id' => '202508-persistent-fail-1', 'title' => 'Persistent Fail 1', 'platform' => 'Instagram', 'pilar' => 'C' },
              { 'id' => '202508-persistent-fail-2', 'title' => 'Persistent Fail 2', 'platform' => 'Instagram', 'pilar' => 'A' },
              { 'id' => '202508-success-item', 'title' => 'Success Item', 'platform' => 'Instagram', 'pilar' => 'E' }
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
      
      let(:service) { described_class.new(strategy_plan: strategy_plan) }

      before do
        # Mock persistent failures for specific items during initial creation
        original_method = service.method(:create_content_item_from_idea)
        
        allow(service).to receive(:create_content_item_from_idea) do |idea, pilar|
          if ['202508-persistent-fail-1', '202508-persistent-fail-2'].include?(idea['id'])
            # Return unpersisted item to simulate failure
            item = CreasContentItem.new(content_id: idea['id'])
            item.errors.add(:content_name, 'persistent validation error')
            item
          else
            # Call original method for successful items
            original_method.call(idea, pilar)
          end
        end
      end

      it 'handles partial success in retry mechanism' do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:error)
        
        result = service.call
        
        # Expected: At least 1 successful item, possibly more depending on retry success
        expect(result.count).to be >= 1
        expect(result.count).to be <= 3
        
        # Should always include the success item
        success_item = result.find { |item| item.content_id == '202508-success-item' }
        expect(success_item).to be_present
        expect(success_item).to be_persisted
        
        # Should log retry attempts
        expect(Rails.logger).to have_received(:info).with(/Created \d+\/3 items\. Retrying missing content/)
        expect(Rails.logger).to have_received(:info).with(/ContentItemInitializerService: Final count \d+\/3 items/)
      end
    end

    context 'when weekly_plan is empty' do
      let(:strategy_plan) do
        create(:creas_strategy_plan, 
               user: user, 
               brand: brand, 
               weekly_plan: [],
               month: '2025-08')
      end
      
      let(:service) { described_class.new(strategy_plan: strategy_plan) }

      it 'returns empty array without retry attempts' do
        allow(Rails.logger).to receive(:info)
        
        result = service.call
        
        expect(result).to eq([])
        expect(CreasContentItem.count).to eq(0)
        
        # Should not log any retry attempts
        expect(Rails.logger).not_to have_received(:info)
      end
    end

    context 'when weekly_plan has weeks with no ideas' do
      let(:weekly_plan) do
        [
          {
            'ideas' => [
              { 'id' => '202508-test-item', 'title' => 'Test Item', 'platform' => 'Instagram', 'pilar' => 'C' }
            ]
          },
          {
            'ideas' => []  # Empty week
          },
          {
            'ideas' => nil  # Null ideas
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
      
      let(:service) { described_class.new(strategy_plan: strategy_plan) }

      it 'handles empty weeks correctly and guarantees only valid content quantities' do
        allow(Rails.logger).to receive(:info)
        
        result = service.call
        
        # Should create exactly 1 item (only the valid one)
        expect(result.count).to eq(1)
        expect(result.first.content_id).to eq('202508-test-item')
        
        # Should log correct final count
        expect(Rails.logger).to have_received(:info).with("ContentItemInitializerService: Final count 1/1 items")
      end
    end
  end

  describe 'retry mechanism implementation details' do
    let(:weekly_plan) do
      [
        {
          'ideas' => [
            { 'id' => 'test-retry-item', 'title' => 'Test Retry', 'description' => 'Original description', 'platform' => 'Instagram', 'pilar' => 'C' }
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
    
    let(:service) { described_class.new(strategy_plan: strategy_plan) }

    context 'enhanced uniqueness in retry mechanism' do
      it 'creates highly unique content when retrying failed items' do
        # Mock initial failure
        original_create_method = service.method(:create_content_item_from_idea)
        allow(service).to receive(:create_content_item_from_idea) do |idea, pilar|
          item = CreasContentItem.new(content_id: idea['id'])
          item.errors.add(:content_name, 'duplicate')
          item
        end
        
        # But allow the retry method to work normally
        allow(service).to receive(:create_missing_content_item).and_call_original
        
        result = service.call
        
        expect(result.count).to eq(1)
        created_item = result.first
        
        # Verify enhanced uniqueness features
        expect(created_item.content_name).to include('Version')
        expect(created_item.post_description).to include('UNIQUE VERSION')
        expect(created_item.post_description).to include('specifically created for week 1')
        expect(created_item.text_base).to include('WEEK 1 EDITION')
        expect(created_item.text_base).to include('VERSION')
      end
    end

    context 'retry attempt tracking' do
      before do
        # Mock failure for initial attempt
        original_method = service.method(:create_content_item_from_idea)
        allow(service).to receive(:create_content_item_from_idea) do |idea, pilar|
          item = CreasContentItem.new(content_id: idea['id'])
          item.errors.add(:base, 'simulated failure')
          item
        end
      end

      it 'tracks which items were missing and logs retry attempts' do
        allow(Rails.logger).to receive(:info)
        
        service.call
        
        # Should log the missing content retry
        expect(Rails.logger).to have_received(:info).with("Retrying missing content: test-retry-item - Test Retry")
        expect(Rails.logger).to have_received(:info).with(/Successfully created missing content:/)
      end
    end
  end

  describe 'error handling in quantity guarantee' do
    let(:weekly_plan) do
      [
        {
          'ideas' => [
            { 'id' => 'error-prone-item', 'title' => 'Error Prone', 'platform' => 'Instagram', 'pilar' => 'C' }
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
    
    let(:service) { described_class.new(strategy_plan: strategy_plan) }

    context 'when retry mechanism encounters exceptions' do
      before do
        # Mock both initial creation and retry to fail
        allow(service).to receive(:create_content_item_from_idea) do |idea, pilar|
          item = CreasContentItem.new(content_id: idea['id'])
          item.errors.add(:base, 'initial failure')
          item
        end
        
        # Mock the retry method to raise an exception
        allow(service).to receive(:create_missing_content_item).and_raise(StandardError.new('Retry failed'))
      end

      it 'handles retry exceptions gracefully and continues processing' do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
        
        result = service.call
        
        # Should return empty array since both initial and retry failed
        expect(result.count).to eq(0)
        
        # Should log the error
        expect(Rails.logger).to have_received(:error).with(/Error creating missing content error-prone-item: Retry failed/)
      end
    end
  end
end