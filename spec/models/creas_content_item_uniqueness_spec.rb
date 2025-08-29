require 'rails_helper'

RSpec.describe CreasContentItem, type: :model do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:strategy_plan_2025_06) { create(:creas_strategy_plan, user: user, brand: brand, month: '2025-06') }
  let(:strategy_plan_2025_07) { create(:creas_strategy_plan, user: user, brand: brand, month: '2025-07') }

  describe 'content uniqueness validation' do
    context 'when content name already exists' do
      let!(:existing_item) do
        create(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: strategy_plan_2025_06,
          content_name: 'Welcome New Followers'
        )
      end

      it 'prevents duplicate content names within the same month' do
        duplicate_item = build(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: strategy_plan_2025_06,
          content_name: 'Welcome New Followers'
        )

        expect(duplicate_item).not_to be_valid
        expect(duplicate_item.errors[:content_name]).to include(
          match(/already exists for this brand in 2025-06/)
        )
      end

      it 'prevents duplicate content names across different months' do
        duplicate_item = build(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: strategy_plan_2025_07,
          content_name: 'Welcome New Followers'
        )

        expect(duplicate_item).not_to be_valid
        expect(duplicate_item.errors[:content_name]).to include(
          match(/already exists for this brand.*previously used in 2025-06/)
        )
      end

      it 'allows same content name for different brands' do
        other_brand = create(:brand, user: user)
        other_strategy_plan = create(:creas_strategy_plan, user: user, brand: other_brand, month: '2025-06')

        duplicate_item = build(:creas_content_item,
          user: user,
          brand: other_brand,
          creas_strategy_plan: other_strategy_plan,
          content_name: 'Welcome New Followers'
        )

        expect(duplicate_item).to be_valid
      end
    end

    context 'when post description is similar' do
      let!(:existing_item) do
        create(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: strategy_plan_2025_06,
          content_name: 'Original Content',
          post_description: 'Create a welcoming post for new followers. Highlight what they can expect from following our brand and showcase our community values.'
        )
      end

      it 'prevents very similar post descriptions' do
        similar_item = build(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: strategy_plan_2025_07,
          content_name: 'Different Name',
          post_description: 'Create a welcoming post for new followers. Highlight what they can expect from following our brand and showcase community values.'
        )

        expect(similar_item).not_to be_valid
        expect(similar_item.errors[:post_description]).to include(
          match(/is very similar to existing content from 2025-06/)
        )
      end

      it 'allows different post descriptions' do
        different_item = build(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: strategy_plan_2025_07,
          content_name: 'Different Name',
          post_description: 'Showcase our latest product features and demonstrate how they solve customer problems effectively.'
        )

        expect(different_item).to be_valid
      end

      it 'skips validation for short descriptions' do
        short_description_item = build(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: strategy_plan_2025_07,
          content_name: 'Different Name',
          post_description: 'Short description.'
        )

        expect(short_description_item).to be_valid
      end
    end

    context 'when text_base is similar' do
      let!(:existing_item) do
        create(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: strategy_plan_2025_06,
          content_name: 'Original Content',
          text_base: 'Welcome to our entrepreneurial community! We are here to support your journey with valuable insights, practical tips, and inspiring success stories. Join thousands of entrepreneurs who trust us for their business growth.'
        )
      end

      it 'prevents very similar text_base content' do
        similar_item = build(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: strategy_plan_2025_07,
          content_name: 'Different Name',
          text_base: 'Welcome to our entrepreneurial community! We are here to support your journey with valuable insights, practical tips, and inspiring stories. Join thousands of entrepreneurs who trust us for business growth.'
        )

        expect(similar_item).not_to be_valid
        expect(similar_item.errors[:text_base]).to include(
          match(/is very similar to existing content from 2025-06/)
        )
      end

      it 'allows different text_base content' do
        different_item = build(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: strategy_plan_2025_07,
          content_name: 'Different Name',
          text_base: 'Discover the latest trends in digital marketing and learn how to implement effective strategies for your business. Our expert team shares proven techniques used by successful companies worldwide.'
        )

        expect(different_item).to be_valid
      end

      it 'skips validation for short text_base' do
        short_text_item = build(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: strategy_plan_2025_07,
          content_name: 'Different Name',
          text_base: 'Short text content.'
        )

        expect(short_text_item).to be_valid
      end
    end

    describe '#calculate_text_similarity' do
      let(:content_item) { build(:creas_content_item) }

      it 'returns 1.0 for identical texts' do
        text = "Hello world this is a test"
        expect(content_item.send(:calculate_text_similarity, text, text)).to eq(1.0)
      end

      it 'returns 0.0 for completely different texts' do
        text1 = "Hello world"
        text2 = "Goodbye mars"
        expect(content_item.send(:calculate_text_similarity, text1, text2)).to eq(0.0)
      end

      it 'returns similarity score for partially similar texts' do
        text1 = "Hello world this is a test"
        text2 = "Hello world this is different"
        similarity = content_item.send(:calculate_text_similarity, text1, text2)
        expect(similarity).to be > 0.5
        expect(similarity).to be < 1.0
      end

      it 'handles empty or nil texts' do
        expect(content_item.send(:calculate_text_similarity, "", "test")).to eq(0.0)
        expect(content_item.send(:calculate_text_similarity, nil, "test")).to eq(0.0)
        expect(content_item.send(:calculate_text_similarity, "test", "")).to eq(0.0)
      end

      it 'ignores punctuation and case differences' do
        text1 = "Hello, World! This is a TEST."
        text2 = "hello world this is a test"
        expect(content_item.send(:calculate_text_similarity, text1, text2)).to eq(1.0)
      end
    end
  end

  describe 'performance considerations' do
    it 'does not perform expensive similarity checks when not needed' do
      # Create content without long descriptions or text_base
      item = build(:creas_content_item,
        user: user,
        brand: brand,
        creas_strategy_plan: strategy_plan_2025_06,
        content_name: 'Unique Name',
        post_description: 'Short',
        text_base: 'Also short'
      )

      expect(item).to be_valid
    end
  end
end
