require 'rails_helper'

RSpec.describe 'Noctua Content Generation', type: :integration do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:month) { "2025-06" }

  let(:brief) do
    {
      brand_name: "Test Brand",
      sector: "Technology",
      audience_profile: "Young professionals",
      languages: "en-US",
      target_region: "United States",
      timezone: "America/New_York",
      value_proposition: "Innovative solutions",
      main_offer: "Software products",
      purpose: "Empower businesses",
      tone_style: "Professional yet friendly",
      platforms: [ "Instagram", "TikTok" ],
      monthly_themes: "Innovation week",
      primary_objective: "awareness",
      available_resources: "Stock videos, AI avatars",
      posts_per_week: 2,
      remix_references: "Tech influencer content",
      restrictions: "No political content"
    }
  end

  describe 'content generation with proper frequency' do
    let(:mock_ai_response) do
      {
        "brand_name" => "Test Brand",
        "month" => "2025-06",
        "objective_of_the_month" => "awareness",
        "frequency_per_week" => 2,
        "content_distribution" => {
          "C" => {
            "goal" => "Increase brand awareness",
            "ideas" => [
              {
                "id" => "202506-testbrand-C-w1-i1",
                "title" => "Week 1 Content Idea",
                "description" => "Test description",
                "pilar" => "C",
                "platform" => "Instagram"
              },
              {
                "id" => "202506-testbrand-C-w2-i1",
                "title" => "Week 2 Content Idea",
                "description" => "Test description 2",
                "pilar" => "C",
                "platform" => "Instagram"
              },
              {
                "id" => "202506-testbrand-C-w3-i1",
                "title" => "Week 3 Content Idea",
                "description" => "Test description 3",
                "pilar" => "C",
                "platform" => "Instagram"
              },
              {
                "id" => "202506-testbrand-C-w4-i1",
                "title" => "Week 4 Content Idea",
                "description" => "Test description 4",
                "pilar" => "C",
                "platform" => "Instagram"
              }
            ]
          },
          "E" => {
            "goal" => "Engage audience",
            "ideas" => [
              {
                "id" => "202506-testbrand-E-w1-i1",
                "title" => "Week 1 Entertainment",
                "description" => "Fun content",
                "pilar" => "E",
                "platform" => "Instagram"
              },
              {
                "id" => "202506-testbrand-E-w2-i1",
                "title" => "Week 2 Entertainment",
                "description" => "Fun content 2",
                "pilar" => "E",
                "platform" => "Instagram"
              },
              {
                "id" => "202506-testbrand-E-w3-i1",
                "title" => "Week 3 Entertainment",
                "description" => "Fun content 3",
                "pilar" => "E",
                "platform" => "Instagram"
              },
              {
                "id" => "202506-testbrand-E-w4-i1",
                "title" => "Week 4 Entertainment",
                "description" => "Fun content 4",
                "pilar" => "E",
                "platform" => "Instagram"
              }
            ]
          }
        },
        "weekly_plan" => [
          {
            "week" => 1,
            "publish_cadence" => 2,
            "ideas" => [
              {
                "id" => "202506-testbrand-w1-i1-C",
                "title" => "Week 1 Content Idea",
                "description" => "Test description",
                "pilar" => "C",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              },
              {
                "id" => "202506-testbrand-w1-i2-E",
                "title" => "Week 1 Entertainment",
                "description" => "Fun content",
                "pilar" => "E",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              }
            ]
          },
          {
            "week" => 2,
            "publish_cadence" => 2,
            "ideas" => [
              {
                "id" => "202506-testbrand-w2-i1-C",
                "title" => "Week 2 Content Idea",
                "description" => "Test description 2",
                "pilar" => "C",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              },
              {
                "id" => "202506-testbrand-w2-i2-E",
                "title" => "Week 2 Entertainment",
                "description" => "Fun content 2",
                "pilar" => "E",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              }
            ]
          },
          {
            "week" => 3,
            "publish_cadence" => 2,
            "ideas" => [
              {
                "id" => "202506-testbrand-w3-i1-C",
                "title" => "Week 3 Content Idea",
                "description" => "Test description 3",
                "pilar" => "C",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              },
              {
                "id" => "202506-testbrand-w3-i2-E",
                "title" => "Week 3 Entertainment",
                "description" => "Fun content 3",
                "pilar" => "E",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              }
            ]
          },
          {
            "week" => 4,
            "publish_cadence" => 2,
            "ideas" => [
              {
                "id" => "202506-testbrand-w4-i1-C",
                "title" => "Week 4 Content Idea",
                "description" => "Test description 4",
                "pilar" => "C",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              },
              {
                "id" => "202506-testbrand-w4-i2-E",
                "title" => "Week 4 Entertainment",
                "description" => "Fun content 4",
                "pilar" => "E",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              }
            ]
          }
        ]
      }.to_json
    end

    before do
      mock_client = instance_double(GinggaOpenAI::ChatClient)
      allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:chat!).and_return(mock_ai_response)
    end

    it 'generates correct number of content items for frequency_per_week = 2' do
      service = Creas::NoctuaStrategyService.new(user: user, brief: brief, brand: brand, month: month)
      strategy_plan = service.call_sync

      expect(strategy_plan).to be_persisted
      expect(strategy_plan.content_distribution).to be_present

      # Should have 2 posts per week * 4 weeks = 8 total content ideas
      total_ideas = 0
      strategy_plan.content_distribution.each do |pilar, data|
        next unless data.is_a?(Hash) && data["ideas"].present?
        total_ideas += data["ideas"].length
      end

      expect(total_ideas).to eq(8)
    end

    it 'creates content items distributed across all 4 weeks' do
      service = Creas::NoctuaStrategyService.new(user: user, brief: brief, brand: brand, month: month)
      strategy_plan = service.call_sync

      # Initialize content items from the strategy
      content_items = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call

      expect(content_items.length).to eq(8)

      # Verify content is distributed across all 4 weeks
      weeks_with_content = content_items.map(&:week).uniq.sort
      expect(weeks_with_content).to eq([ 1, 2, 3, 4 ])

      # Verify we have 2 posts per week (frequency_per_week = 2)
      (1..4).each do |week|
        week_items = content_items.select { |item| item.week == week }
        expect(week_items.length).to eq(2)
      end
    end
  end

  describe 'voxa refinement should update not duplicate' do
    let(:strategy_plan) { create(:creas_strategy_plan, user: user, brand: brand) }

    let!(:original_item) do
      create(:creas_content_item,
        user: user,
        brand: brand,
        creas_strategy_plan: strategy_plan,
        content_id: "202506-testbrand-C-w1-i1",
        origin_id: "202506-testbrand-C-w1-i1",
        status: "draft",
        day_of_the_week: "Monday")
    end

    let(:voxa_response) do
      {
        "items" => [
          {
            "id" => "202506-testbrand-w1-i1-C",
            "origin_id" => "202506-testbrand-C-w1-i1",
            "week" => 1,
            "week_index" => 1,
            "content_name" => "Updated Content Name",
            "status" => "in_production",
            "creation_date" => "2025-06-01",
            "publish_date" => "2025-06-01",
            "content_type" => "Video",
            "platform" => "Instagram Reels",
            "aspect_ratio" => "9:16",
            "language" => "en-US",
            "pilar" => "C",
            "template" => "solo_avatars",
            "video_source" => "none",
            "post_description" => "Test description",
            "text_base" => "Test text",
            "hashtags" => "#test #content #brand"
          }
        ]
      }.to_json
    end

    before do
      mock_client = instance_double(GinggaOpenAI::ChatClient)
      allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:chat!).and_return(voxa_response)
    end

    it 'updates existing content items instead of creating duplicates' do
      initial_count = CreasContentItem.count

      Creas::VoxaContentService.new(strategy_plan: strategy_plan).call

      # Should not increase the total count
      expect(CreasContentItem.count).to eq(initial_count)

      # Should update the existing item
      updated_item = CreasContentItem.find(original_item.id)
      expect(updated_item.status).to eq("in_production")
      expect(updated_item.content_name).to eq("Updated Content Name")
      expect(updated_item.content_id).to eq("202506-testbrand-C-w1-i1") # Preserves original ID
      expect(updated_item.day_of_the_week).to eq("Monday") # Preserves day assignment
    end
  end
end
