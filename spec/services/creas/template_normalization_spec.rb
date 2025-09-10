require 'rails_helper'

RSpec.describe 'Template Normalization', type: :service do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:strategy_plan) do
    create(:creas_strategy_plan,
      user: user,
      brand: brand,
      weekly_plan: [
        {
          "ideas" => [
            {
              "id" => "test-invalid-template",
              "title" => "Test Content with Invalid Template",
              "hook" => "Test hook",
              "description" => "Test description",
              "platform" => "Instagram",
              "pilar" => "C",
              "recommended_template" => "invalid_template_name",
              "video_source" => "none"
            }
          ]
        }
      ]
    )
  end

  describe 'ContentItemInitializerService template normalization' do
    let(:service) { Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan) }

    it 'normalizes invalid template to valid one' do
      # This should not raise an error even with invalid template
      expect { service.call }.not_to raise_error

      created_item = strategy_plan.creas_content_items.first
      expect(created_item).to be_present
      expect(created_item.template).to eq("only_avatars") # Should be normalized
    end

    it 'handles common template variations' do
      test_cases = [
        { input: "text", expected: "only_avatars" },
        { input: "avatar", expected: "only_avatars" },
        { input: "carousel", expected: "narration_over_7_images" },
        { input: "slideshow", expected: "narration_over_7_images" },
        { input: "videos", expected: "one_to_three_videos" },
        { input: nil, expected: "only_avatars" },
        { input: "", expected: "only_avatars" }
      ]

      test_cases.each do |test_case|
        result = service.send(:normalize_template, test_case[:input])
        expect(result).to eq(test_case[:expected])
      end
    end
  end

  describe 'GenerateVoxaContentJob template normalization' do
    let(:job) { GenerateVoxaContentJob.new }

    it 'normalizes invalid templates from Voxa response' do
      test_cases = [
        { input: "unknown_template", expected: "only_avatars" },
        { input: "text", expected: "only_avatars" },
        { input: "carousel", expected: "narration_over_7_images" },
        { input: "videos", expected: "one_to_three_videos" }
      ]

      test_cases.each do |test_case|
        result = job.send(:normalize_template, test_case[:input])
        expect(result).to eq(test_case[:expected])
      end
    end
  end

  describe 'Error Recovery System' do
    let(:service) { Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan) }

    it 'recovers from multiple validation errors' do
      # Create a strategy plan with problematic data that would normally fail validation
      problematic_strategy = create(:creas_strategy_plan,
        user: user,
        brand: brand,
        weekly_plan: [
          {
            "ideas" => [
              {
                "id" => "problematic-content-1",
                "title" => "Content with Multiple Issues",
                "hook" => "Test hook",
                "description" => "Test description",
                "platform" => "InvalidPlatform",
                "pilar" => "X", # Invalid pilar
                "recommended_template" => "invalid_template",
                "video_source" => "invalid_source"
              }
            ]
          }
        ]
      )

      problematic_service = Creas::ContentItemInitializerService.new(strategy_plan: problematic_strategy)

      # Should not raise error and should create content
      expect { problematic_service.call }.not_to raise_error

      created_items = problematic_strategy.creas_content_items
      expect(created_items.count).to eq(1)

      item = created_items.first
      expect(item.template).to eq("only_avatars") # Should be normalized
      expect(item.pilar).to eq("C") # Should be fixed
      expect(item.video_source).to eq("none") # Should be fixed
      expect(item.status).to eq("draft") # Should be valid
    end

    it 'uses nuclear recovery option when all else fails' do
      # Create content with duplicate name to trigger recovery
      existing_item = create(:creas_content_item,
        user: user,
        brand: brand,
        creas_strategy_plan: strategy_plan,
        content_name: "Test Content with Invalid Template (Week 1)",
        content_id: "existing-content-1"
      )

      # This should trigger the recovery system due to duplicate content name
      expect { service.call }.not_to raise_error

      # Should still create content even with naming conflicts
      expect(strategy_plan.creas_content_items.count).to be >= 1
    end
  end

  describe 'Content Guarantee System' do
    let(:strategy_plan_with_multiple_content) do
      create(:creas_strategy_plan,
        user: user,
        brand: brand,
        weekly_plan: [
          {
            "ideas" => [
              { "id" => "content-1", "title" => "Content 1", "pilar" => "C", "recommended_template" => "invalid_template_1" },
              { "id" => "content-2", "title" => "Content 2", "pilar" => "R", "recommended_template" => "invalid_template_2" },
              { "id" => "content-3", "title" => "Content 3", "pilar" => "E", "recommended_template" => "invalid_template_3" }
            ]
          }
        ]
      )
    end

    it 'guarantees all content is saved regardless of template issues' do
      service = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan_with_multiple_content)

      # Should create all 3 content items even with invalid templates
      expect { service.call }.not_to raise_error

      created_items = strategy_plan_with_multiple_content.creas_content_items
      expect(created_items.count).to eq(3)

      # All should have valid normalized templates
      created_items.each do |item|
        expect(%w[only_avatars avatar_and_video narration_over_7_images remix one_to_three_videos]).to include(item.template)
      end
    end
  end
end
