require 'rails_helper'

RSpec.describe Creas::ContentItemInitializerService do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:strategy_plan) { create(:creas_strategy_plan, user: user, brand: brand, month: '2025-08') }

  let(:service) { described_class.new(strategy_plan: strategy_plan) }

  describe 'duplicate content handling' do
    let(:content_distribution) do
      {
        "A" => {
          "ideas" => [
            {
              "id" => "202508-test-A-w1-i1",
              "title" => "Welcome New Followers",
              "description" => "Create a welcoming post for new followers.",
              "platform" => "Instagram",
              "pilar" => "A"
            }
          ]
        }
      }
    end

    before do
      strategy_plan.update!(content_distribution: content_distribution)
    end

    context 'when duplicate content name exists' do
      let!(:existing_item) do
        existing_plan = create(:creas_strategy_plan, user: user, brand: brand, month: '2025-06')
        create(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: existing_plan,
          content_name: 'Welcome New Followers'
        )
      end

      it 'creates content with unique name variations' do
        items = service.call

        expect(items.size).to eq(1)
        created_item = items.first

        expect(created_item).to be_persisted
        expect(created_item.content_name).not_to eq('Welcome New Followers')
        expect(created_item.content_name).to match(/Welcome New Followers.*2025-08|Content Focus|Week 1|Advertising/)
      end
    end

    context 'when similar description exists' do
      let(:existing_description) { "Create a welcoming post for new followers with detailed instructions." }

      let!(:existing_item) do
        existing_plan = create(:creas_strategy_plan, user: user, brand: brand, month: '2025-06')
        create(:creas_content_item,
          user: user,
          brand: brand,
          creas_strategy_plan: existing_plan,
          content_name: 'Different Name',
          post_description: existing_description
        )
      end

      let(:similar_content_distribution) do
        {
          "A" => {
            "ideas" => [
              {
                "id" => "202508-test-A-w1-i1",
                "title" => "Welcome Post",
                "description" => "Create a welcoming post for new followers with detailed instructions.",
                "platform" => "Instagram",
                "pilar" => "A"
              }
            ]
          }
        }
      end

      before do
        strategy_plan.update!(content_distribution: similar_content_distribution)
      end

      it 'modifies description to make it unique' do
        items = service.call

        expect(items.size).to eq(1)
        created_item = items.first

        expect(created_item).to be_persisted
        expect(created_item.post_description).not_to eq(existing_description)
        expect(created_item.post_description).to include('[Promotional content for 2025-08, Week 1]')
      end
    end

    describe 'uniqueness helper methods' do
      describe '#make_content_name_unique' do
        it 'creates meaningful variations' do
          original_name = "Test Content"
          week = 1
          pilar = "A"

          unique_name = service.send(:make_content_name_unique, original_name, week, pilar)

          expect(unique_name).to match(/Test Content.*(2025-08|Advertising|Week 1)/)
          expect(unique_name).not_to eq(original_name)
        end

        it 'handles existing variations by trying multiple options' do
          original_name = "Popular Content"

          # Create existing items with some variations
          create(:creas_content_item,
            user: user,
            brand: brand,
            creas_strategy_plan: strategy_plan,
            content_name: "Popular Content (2025-08)"
          )

          unique_name = service.send(:make_content_name_unique, original_name, 1, "A")

          expect(unique_name).not_to eq("Popular Content (2025-08)")
          expect(unique_name).to include("Popular Content")
        end

        it 'falls back to timestamp when all variations exist' do
          original_name = "Very Popular Content"

          # Create items with all common variations
          [
            "Very Popular Content (2025-08)",
            "Very Popular Content - Advertising Focus",
            "Very Popular Content - Week 1",
            "Very Popular Content (Advertising Edition)",
            "Very Popular Content - 2025-08 Update"
          ].each do |variation|
            create(:creas_content_item,
              user: user,
              brand: brand,
              creas_strategy_plan: strategy_plan,
              content_name: variation
            )
          end

          unique_name = service.send(:make_content_name_unique, original_name, 1, "A")

          expect(unique_name).to match(/Very Popular Content \(\d{8}\)/)
        end
      end

      describe '#make_description_unique' do
        it 'adds contextual suffix to descriptions' do
          original_desc = "This is a test description."

          unique_desc = service.send(:make_description_unique, original_desc, 2, "C")

          expect(unique_desc).to include(original_desc)
          expect(unique_desc).to include("[Educational content for 2025-08, Week 2]")
        end
      end

      describe '#make_text_base_unique' do
        it 'adds contextual hashtags to text base' do
          original_text = "This is test content for our brand."

          unique_text = service.send(:make_text_base_unique, original_text, 3, "E")

          expect(unique_text).to include(original_text)
          expect(unique_text).to include("#Entertainment")
          expect(unique_text).to include("#Week3")
          expect(unique_text).to include("#202508")
        end
      end

      describe '#pilar_full_name' do
        it 'returns full names for pilar codes' do
          expect(service.send(:pilar_full_name, "C")).to eq("Content")
          expect(service.send(:pilar_full_name, "R")).to eq("Relationship")
          expect(service.send(:pilar_full_name, "E")).to eq("Entertainment")
          expect(service.send(:pilar_full_name, "A")).to eq("Advertising")
          expect(service.send(:pilar_full_name, "S")).to eq("Sales")
          expect(service.send(:pilar_full_name, "X")).to eq("X")
        end
      end

      describe '#get_pilar_context' do
        it 'returns contextual descriptions for pilars' do
          expect(service.send(:get_pilar_context, "C")).to eq("Educational")
          expect(service.send(:get_pilar_context, "R")).to eq("Community")
          expect(service.send(:get_pilar_context, "E")).to eq("Entertainment")
          expect(service.send(:get_pilar_context, "A")).to eq("Promotional")
          expect(service.send(:get_pilar_context, "S")).to eq("Sales-focused")
          expect(service.send(:get_pilar_context, "X")).to eq("General")
        end
      end
    end
  end

  describe 'error handling integration' do
    let(:invalid_content_distribution) do
      {
        "A" => {
          "ideas" => [
            {
              "id" => "invalid-id",
              "title" => "",  # Invalid: empty title
              "platform" => "Instagram",
              "pilar" => "A"
            }
          ]
        }
      }
    end

    before do
      strategy_plan.update!(content_distribution: invalid_content_distribution)
    end

    it 'handles validation errors gracefully' do
      expect {
        items = service.call
        # Service returns only valid persisted items, so invalid items are filtered out
        expect(items.size).to eq(0)
      }.not_to raise_error
    end
  end
end
