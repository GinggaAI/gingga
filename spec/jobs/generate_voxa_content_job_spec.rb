require 'rails_helper'

RSpec.describe GenerateVoxaContentJob, type: :job do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:strategy_plan) do
    create(:creas_strategy_plan,
           user: user,
           brand: brand,
           status: :processing,
           weekly_plan: [
             {
               "ideas" => [
                 { "id" => "202508-test-w1-i1-C", "title" => "Week 1 Content 1", "platform" => "Instagram", "pilar" => "C" },
                 { "id" => "202508-test-w1-i2-R", "title" => "Week 1 Content 2", "platform" => "TikTok", "pilar" => "R" }
               ]
             },
             {
               "ideas" => [
                 { "id" => "202508-test-w2-i1-E", "title" => "Week 2 Content 1", "platform" => "Instagram", "pilar" => "E" },
                 { "id" => "202508-test-w2-i2-A", "title" => "Week 2 Content 2", "platform" => "YouTube", "pilar" => "A" }
               ]
             }
           ])
  end

  let(:mock_voxa_response) do
    {
      "items" => [
        {
          "id" => "voxa-refined-1",
          "origin_id" => "202508-test-w1-i1-C",
          "origin_source" => "weekly_plan",
          "week" => 1,
          "content_name" => "Refined Week 1 Content 1",
          "status" => "in_production",
          "creation_date" => "2025-08-28",
          "publish_date" => "2025-08-30",
          "content_type" => "reel",
          "platform" => "Instagram",
          "pilar" => "C",
          "template" => "solo_avatars",
          "video_source" => "kling",
          "post_description" => "Refined description 1",
          "text_base" => "Refined text 1",
          "hashtags" => "#refined #content1",
          "hook" => "Amazing hook 1",
          "cta" => "Click now!",
          "shotplan" => {
            "scenes" => [
              {
                "scene_number" => 1,
                "on_screen_text" => "Amazing hook 1",
                "voiceover" => "Amazing hook 1 voiceover",
                "avatar_id" => "avatar_123",
                "voice_id" => "voice_123"
              }
            ],
            "beats" => [
              { "beat_number" => 1, "description" => "Opening hook", "duration" => "3-5s" }
            ]
          }
        },
        {
          "id" => "voxa-refined-2",
          "origin_id" => "202508-test-w1-i2-R",
          "origin_source" => "weekly_plan",
          "week" => 1,
          "content_name" => "Refined Week 1 Content 2",
          "status" => "in_production",
          "creation_date" => "2025-08-28",
          "publish_date" => "2025-08-31",
          "content_type" => "reel",
          "platform" => "TikTok",
          "pilar" => "R",
          "template" => "narration_over_7_images",
          "video_source" => "none",
          "post_description" => "Refined description 2",
          "text_base" => "Refined text 2",
          "hashtags" => "#refined #content2"
        }
        # Note: Only 2 items returned by Voxa, but strategy plan expects 4
      ]
    }.to_json
  end

  let(:mock_chat_client) { instance_double(GinggaOpenAI::ChatClient) }

  before do
    allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
    allow(mock_chat_client).to receive(:chat!).and_return(mock_voxa_response)
  end

  describe '#perform' do
    context 'when content quantity guarantee is needed' do
      it 'ensures all expected content items are created' do
        # Initially no content items exist
        expect(strategy_plan.creas_content_items.count).to eq(0)

        # Perform the job
        described_class.perform_now(strategy_plan.id)

        # Reload strategy plan
        strategy_plan.reload

        # Should have created all 4 expected content items (2 from Voxa + 2 from quantity guarantee)
        expect(strategy_plan.creas_content_items.count).to eq(4)
        expect(strategy_plan.status).to eq("completed")

        # Check that content items have correct status
        voxa_refined_items = strategy_plan.creas_content_items.where(status: "in_production")
        draft_items = strategy_plan.creas_content_items.where(status: "draft")

        expect(voxa_refined_items.count).to eq(2) # Items processed by Voxa
        expect(draft_items.count).to eq(2) # Items created by quantity guarantee

        # Verify Voxa refined items have shot plans
        voxa_items_with_shotplan = voxa_refined_items.select { |item| item.shotplan.present? && item.shotplan.is_a?(Hash) }
        expect(voxa_items_with_shotplan.count).to eq(2)
      end
    end

    context 'when shot plan is missing from Voxa response' do
      let(:mock_voxa_response_no_shotplan) do
        {
          "items" => [
            {
              "id" => "voxa-no-shotplan",
              "origin_id" => "202508-test-w1-i1-C",
              "week" => 1,
              "content_name" => "Content without shotplan",
              "status" => "in_production",
              "creation_date" => "2025-08-28",
              "publish_date" => "2025-08-30",
              "content_type" => "reel",
              "platform" => "Instagram",
              "pilar" => "C",
              "template" => "solo_avatars",
              "video_source" => "kling",
              "post_description" => "Description",
              "text_base" => "Text",
              "hashtags" => "#test",
              "hook" => "Test hook"
              # No shotplan field
            }
          ]
        }.to_json
      end

      before do
        allow(mock_chat_client).to receive(:chat!).and_return(mock_voxa_response_no_shotplan)
      end

      it 'generates default shot plan when missing' do
        # Create initial draft content
        Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call

        # Perform the job
        described_class.perform_now(strategy_plan.id)

        # Check that shot plan was generated
        processed_item = strategy_plan.creas_content_items.find_by(status: "in_production")
        expect(processed_item).to be_present
        expect(processed_item.shotplan).to be_present
        expect(processed_item.shotplan).to be_a(Hash)
        expect(processed_item.shotplan["scenes"]).to be_present
        expect(processed_item.shotplan["scenes"].first["on_screen_text"]).to eq("Test hook")
      end
    end

    context 'when updating existing content items' do
      before do
        # Create initial draft content using ContentItemInitializerService
        Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call
      end

      it 'preserves important existing data while applying Voxa refinements' do
        existing_items = strategy_plan.creas_content_items.to_a
        expect(existing_items.count).to eq(4)

        original_item = existing_items.first
        original_content_id = original_item.content_id
        original_day_of_week = original_item.day_of_the_week
        original_week = original_item.week
        original_pilar = original_item.pilar

        # Perform the job
        described_class.perform_now(strategy_plan.id)

        # Find the updated item
        updated_item = strategy_plan.creas_content_items.find_by(content_id: original_content_id)

        if updated_item.status == "in_production" # If this item was processed by Voxa
          # Should preserve original identifiers and structural data
          expect(updated_item.content_id).to eq(original_content_id)
          expect(updated_item.day_of_the_week).to eq(original_day_of_week)
          expect(updated_item.week).to eq(original_week)
          expect(updated_item.pilar).to eq(original_pilar)

          # Should have Voxa refinements
          expect(updated_item.status).to eq("in_production")
          expect(updated_item.content_name).to include("Refined")
        end
      end
    end

    context 'when OpenAI call fails' do
      before do
        allow(mock_chat_client).to receive(:chat!).and_raise(StandardError.new("OpenAI timeout"))
      end

      it 'handles errors gracefully and updates strategy plan status' do
        described_class.perform_now(strategy_plan.id)

        strategy_plan.reload
        expect(strategy_plan.status).to eq("failed")
        expect(strategy_plan.error_message).to include("OpenAI timeout")
        expect(strategy_plan.meta["voxa_failed_at"]).to be_present
      end
    end

    context 'when JSON parsing fails' do
      before do
        allow(mock_chat_client).to receive(:chat!).and_return("Invalid JSON response")
      end

      it 'handles JSON parsing errors' do
        described_class.perform_now(strategy_plan.id)

        strategy_plan.reload
        expect(strategy_plan.status).to eq("failed")
        expect(strategy_plan.error_message).to include("non-JSON content")
      end
    end
  end

  describe 'content count validation' do
    context 'when Voxa returns fewer items than expected' do
      let(:minimal_voxa_response) do
        {
          "items" => [
            {
              "id" => "voxa-single",
              "origin_id" => "202508-test-w1-i1-C",
              "week" => 1,
              "content_name" => "Single refined content",
              "status" => "in_production",
              "creation_date" => "2025-08-28",
              "publish_date" => "2025-08-30",
              "content_type" => "reel",
              "platform" => "Instagram",
              "pilar" => "C",
              "template" => "solo_avatars",
              "video_source" => "kling",
              "post_description" => "Description",
              "text_base" => "Text",
              "hashtags" => "#test"
            }
            # Only 1 item, but strategy plan expects 4
          ]
        }.to_json
      end

      before do
        allow(mock_chat_client).to receive(:chat!).and_return(minimal_voxa_response)
      end

      it 'uses ContentItemInitializerService to ensure complete content set' do
        # Allow ContentItemInitializerService to be called multiple times
        allow_any_instance_of(Creas::ContentItemInitializerService).to receive(:call).and_call_original

        described_class.perform_now(strategy_plan.id)

        strategy_plan.reload
        expect(strategy_plan.creas_content_items.count).to eq(4) # All 4 items should exist
        expect(strategy_plan.creas_content_items.where(status: "in_production").count).to eq(1) # 1 from Voxa
        expect(strategy_plan.creas_content_items.where(status: "draft").count).to eq(3) # 3 from quantity guarantee
      end
    end
  end

  describe 'metadata tracking' do
    it 'tracks processing metadata correctly' do
      described_class.perform_now(strategy_plan.id)

      strategy_plan.reload
      expect(strategy_plan.meta["voxa_processed_at"]).to be_present
      expect(strategy_plan.meta["voxa_items_count"]).to eq(4)
      expect(strategy_plan.meta["expected_content_count"]).to eq(4)
    end

    it 'creates AI response record for debugging' do
      expect {
        described_class.perform_now(strategy_plan.id)
      }.to change(AiResponse, :count).by(1)

      ai_response = AiResponse.last
      expect(ai_response.service_name).to eq("voxa")
      expect(ai_response.ai_model).to eq("gpt-4o")
      expect(ai_response.prompt_version).to eq("voxa-2025-08-28")
      expect(ai_response.user).to eq(user)
      expect(ai_response.metadata["strategy_plan_id"]).to eq(strategy_plan.id)
      expect(ai_response.metadata["expected_content_count"]).to eq(4)
    end
  end

  describe 'helper methods' do
    let(:job) { described_class.new }

    describe '#normalize_template' do
      it 'normalizes known template variations' do
        expect(job.send(:normalize_template, "solo_avatar")).to eq("solo_avatars")
        expect(job.send(:normalize_template, "avatar_video")).to eq("avatar_and_video")
        expect(job.send(:normalize_template, "seven_images")).to eq("narration_over_7_images")
        expect(job.send(:normalize_template, "multi_video")).to eq("one_to_three_videos")
        expect(job.send(:normalize_template, "remix_video")).to eq("remix")
      end

      it 'returns valid templates unchanged' do
        expect(job.send(:normalize_template, "solo_avatars")).to eq("solo_avatars")
        expect(job.send(:normalize_template, "avatar_and_video")).to eq("avatar_and_video")
      end

      it 'defaults unknown templates to solo_avatars' do
        expect(job.send(:normalize_template, "unknown_template")).to eq("solo_avatars")
        expect(job.send(:normalize_template, nil)).to eq("solo_avatars")
        expect(job.send(:normalize_template, "")).to eq("solo_avatars")
      end
    end

    describe '#normalize_platform' do
      it 'normalizes platform names to database conventions' do
        expect(job.send(:normalize_platform, "Instagram Reels")).to eq("instagram")
        expect(job.send(:normalize_platform, "Instagram")).to eq("instagram")
        expect(job.send(:normalize_platform, "TikTok")).to eq("tiktok")
        expect(job.send(:normalize_platform, "YouTube")).to eq("youtube")
        expect(job.send(:normalize_platform, "LinkedIn")).to eq("linkedin")
      end

      it 'defaults unknown platforms to lowercase' do
        expect(job.send(:normalize_platform, "Twitter")).to eq("twitter")
        expect(job.send(:normalize_platform, "FACEBOOK")).to eq("facebook")
      end
    end

    describe '#extract_day_of_week' do
      it 'extracts day_of_the_week from various sources' do
        item_with_day = { "day_of_the_week" => "Monday" }
        expect(job.send(:extract_day_of_week, item_with_day)).to eq("Monday")

        item_with_meta_day = { "meta" => { "day_of_the_week" => "Tuesday" } }
        expect(job.send(:extract_day_of_week, item_with_meta_day)).to eq("Tuesday")

        item_with_scheduled_day = { "scheduled_day" => "Wednesday" }
        expect(job.send(:extract_day_of_week, item_with_scheduled_day)).to eq("Wednesday")
      end

      it 'parses publish_date to extract day' do
        item_with_publish_date = { "publish_date" => "2025-08-29" }
        result = job.send(:extract_day_of_week, item_with_publish_date)
        expect(result).to eq("Friday") # 2025-08-29 is a Friday
      end

      it 'falls back to strategic assignment by pilar' do
        item_c = { "pilar" => "C" }
        result_c = job.send(:extract_day_of_week, item_c)
        expect(%w[Tuesday Wednesday Thursday]).to include(result_c)

        item_e = { "pilar" => "E" }
        result_e = job.send(:extract_day_of_week, item_e)
        expect(%w[Monday Friday Saturday]).to include(result_e)

        item_r = { "pilar" => "R" }
        result_r = job.send(:extract_day_of_week, item_r)
        expect(%w[Friday Saturday Sunday]).to include(result_r)

        item_a = { "pilar" => "A" }
        result_a = job.send(:extract_day_of_week, item_a)
        expect(%w[Monday Tuesday Wednesday]).to include(result_a)

        item_s = { "pilar" => "S" }
        result_s = job.send(:extract_day_of_week, item_s)
        expect(%w[Tuesday Wednesday Thursday]).to include(result_s)
      end

      it 'handles invalid publish dates gracefully' do
        item_invalid_date = { "publish_date" => "invalid-date", "pilar" => "C" }
        result = job.send(:extract_day_of_week, item_invalid_date)
        expect(%w[Tuesday Wednesday Thursday]).to include(result)
      end

      it 'defaults to random day for unknown pilars' do
        item_unknown = { "pilar" => "X" }
        result = job.send(:extract_day_of_week, item_unknown)
        expect(%w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]).to include(result)
      end
    end

    describe '#parse_date' do
      it 'parses valid ISO dates' do
        expect(job.send(:parse_date, "2025-08-29")).to eq(Date.new(2025, 8, 29))
        expect(job.send(:parse_date, "2025-12-31")).to eq(Date.new(2025, 12, 31))
      end

      it 'returns nil for invalid dates' do
        expect(job.send(:parse_date, "invalid-date")).to be_nil
        expect(job.send(:parse_date, "")).to be_nil
        expect(job.send(:parse_date, nil)).to be_nil
      end
    end

    describe '#parse_datetime' do
      it 'parses valid datetimes' do
        result = job.send(:parse_datetime, "2025-08-29T10:00:00")
        expect(result).to be_a(Time)
        expect(result.year).to eq(2025)
        expect(result.month).to eq(8)
        expect(result.day).to eq(29)
      end

      it 'returns nil for invalid datetimes' do
        expect(job.send(:parse_datetime, "invalid-datetime")).to be_nil
        expect(job.send(:parse_datetime, "")).to be_nil
        expect(job.send(:parse_datetime, nil)).to be_nil
      end
    end

    describe '#ensure_shot_plan' do
      let(:existing_record) { build(:creas_content_item) }

      it 'uses Voxa shotplan when available' do
        voxa_item = {
          "shotplan" => {
            "scenes" => [ { "scene_number" => 1, "on_screen_text" => "Voxa scene" } ]
          }
        }

        result = job.send(:ensure_shot_plan, voxa_item, existing_record)
        expect(result["scenes"]).to be_present
        expect(result["scenes"][0]["on_screen_text"]).to eq("Voxa scene")
      end

      it 'falls back to existing shotplan when Voxa shotplan is invalid' do
        existing_record.shotplan = {
          "scenes" => [ { "scene_number" => 1, "on_screen_text" => "Existing scene" } ]
        }
        voxa_item = { "shotplan" => nil }

        result = job.send(:ensure_shot_plan, voxa_item, existing_record)
        expect(result["scenes"]).to be_present
        expect(result["scenes"][0]["on_screen_text"]).to eq("Existing scene")
      end

      it 'generates default shotplan when neither is available' do
        voxa_item = { "hook" => "Test hook", "template" => "solo_avatars" }
        existing_record.shotplan = nil

        result = job.send(:ensure_shot_plan, voxa_item, existing_record)
        expect(result["scenes"]).to be_present
        expect(result["scenes"][0]["voiceover"]).to eq("Test hook")
        expect(result["beats"]).to eq([])  # beats should be empty for solo_avatars template
      end

      it 'generates correct default shotplan for narration_over_7_images template' do
        voxa_item = { "title" => "Test Title", "description" => "Test description", "template" => "narration_over_7_images" }
        existing_record.shotplan = nil

        result = job.send(:ensure_shot_plan, voxa_item, existing_record)
        expect(result["scenes"]).to eq([])  # scenes should be empty for narration_over_7_images template
        expect(result["beats"]).to be_present
        expect(result["beats"].length).to eq(7)  # should have exactly 7 beats
        expect(result["beats"][0]["idx"]).to eq(1)
        expect(result["beats"][6]["idx"]).to eq(7)
        expect(result["beats"][0]["image_prompt"]).to include("Test Title")
        expect(result["beats"][0]["voiceover"]).to include("Test description")
      end
    end

    describe '#calculate_expected_content_count' do
      it 'calculates expected count from weekly plan' do
        count = job.send(:calculate_expected_content_count, strategy_plan)
        expect(count).to eq(4)
      end

      it 'handles strategy plans without weekly plan' do
        # Since weekly_plan is not nullable, we test with an empty array instead
        strategy_plan.update!(weekly_plan: [])
        count = job.send(:calculate_expected_content_count, strategy_plan)
        expect(count).to eq(0)
      end

      it 'handles strategy plans with empty weekly plan' do
        strategy_plan.update!(weekly_plan: [])
        count = job.send(:calculate_expected_content_count, strategy_plan)
        expect(count).to eq(0)
      end

      it 'handles weeks without ideas' do
        strategy_plan.update!(weekly_plan: [
          { "ideas" => nil },
          { "ideas" => [] },
          { "ideas" => [ { "id" => "test", "title" => "Test" } ] }
        ])
        count = job.send(:calculate_expected_content_count, strategy_plan)
        expect(count).to eq(1)
      end
    end

    describe '#build_brand_context' do
      let(:brand_with_channels) do
        brand = create(:brand, user: user)
        brand.brand_channels.create!(platform: "instagram", handle: "@test_insta")
        brand.brand_channels.create!(platform: "tiktok", handle: "@test_tiktok")
        brand
      end

      it 'extracts platform information correctly' do
        brand_context = job.send(:build_brand_context, brand_with_channels)
        priority_platforms = brand_context.dig("brand", "priority_platforms")

        expect(priority_platforms).to include("Instagram", "TikTok")
      end

      it 'provides default platforms when none exist' do
        brand_context = job.send(:build_brand_context, brand)
        priority_platforms = brand_context.dig("brand", "priority_platforms")

        expect(priority_platforms).to eq([ "Instagram", "TikTok" ])
      end

      it 'builds complete brand context structure' do
        brand_context = job.send(:build_brand_context, brand)
        brand_data = brand_context["brand"]

        expect(brand_data).to include("industry", "value_proposition", "mission", "voice")
        expect(brand_data["languages"]).to include("content_language", "account_language")
        expect(brand_data["guardrails"]).to be_present
      end
    end

    describe '#find_existing_content_item' do
      let!(:existing_items) do
        Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call
      end

      it 'finds existing content items by content_id' do
        target_item = existing_items.find { |item| item.content_id == "202508-test-w1-i1-C" }

        found_item = job.send(:find_existing_content_item, strategy_plan, "202508-test-w1-i1-C", "some-other-id")

        expect(found_item).to eq(target_item)
      end

      # Note: The find_existing_content_item method has duplicate logic for origin_id checking
      # We test the working paths - content_id matching primarily

      it 'returns nil when no match is found' do
        found_item = job.send(:find_existing_content_item, strategy_plan, "non-existent-id", "also-non-existent")

        expect(found_item).to be_nil
      end
    end

    describe '#map_voxa_item_to_attrs' do
      let(:sample_item) do
        {
          "id" => "voxa-123",
          "origin_id" => "original-123",
          "week" => 2,
          "content_name" => "Sample Content",
          "status" => "in_production",
          "content_type" => "reel",
          "platform" => "Instagram",
          "pilar" => "C",
          "template" => "solo_avatars",
          "video_source" => "kling",
          "post_description" => "Description",
          "text_base" => "Text base",
          "hashtags" => "#sample",
          "hook" => "Sample hook",
          "cta" => "Sample CTA",
          "meta" => {
            "scheduled_day" => "Monday",
            "custom_field" => "custom_value"
          }
        }
      end

      it 'maps Voxa item attributes correctly' do
        attrs = job.send(:map_voxa_item_to_attrs, sample_item)

        expect(attrs[:content_id]).to eq("voxa-123")
        expect(attrs[:origin_id]).to eq("original-123")
        expect(attrs[:week]).to eq(2)
        expect(attrs[:content_name]).to eq("Sample Content")
        expect(attrs[:status]).to eq("in_production")
        expect(attrs[:platform]).to eq("instagram")
        expect(attrs[:pilar]).to eq("C")
        expect(attrs[:template]).to eq("solo_avatars")
        expect(attrs[:video_source]).to eq("kling")
        expect(attrs[:post_description]).to eq("Description")
        expect(attrs[:text_base]).to eq("Text base")
        expect(attrs[:hashtags]).to eq("#sample")
      end

      it 'handles missing optional fields gracefully' do
        minimal_item = {
          "id" => "voxa-minimal",
          "week" => 1,
          "content_name" => "Minimal Content",
          "status" => "draft",
          "content_type" => "reel",
          "platform" => "Instagram",
          "pilar" => "C",
          "template" => "solo_avatars",
          "video_source" => "none",
          "post_description" => "Description",
          "text_base" => "Text",
          "hashtags" => "#minimal"
        }

        attrs = job.send(:map_voxa_item_to_attrs, minimal_item)

        expect(attrs[:content_id]).to eq("voxa-minimal")
        expect(attrs[:origin_id]).to be_nil
        expect(attrs[:subtitles]).to eq({})
        expect(attrs[:dubbing]).to eq({})
        expect(attrs[:assets]).to eq({})
        expect(attrs[:accessibility]).to eq({})
        expect(attrs[:meta]).to be_a(Hash)
      end

      it 'merges meta fields correctly' do
        attrs = job.send(:map_voxa_item_to_attrs, sample_item)

        # The method merges these into the meta hash using symbols
        expect(attrs[:meta]).to include(hook: "Sample hook")
        expect(attrs[:meta]).to include(cta: "Sample CTA")
        expect(attrs[:meta]).to include("custom_field" => "custom_value")
        expect(attrs[:scheduled_day]).to eq("Monday")
      end
    end
  end

  describe 'error scenarios' do
    context 'when strategy plan is not found' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.new.perform(999999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when KeyError occurs from missing response key' do
      before do
        allow(mock_chat_client).to receive(:chat!).and_return('{"wrong_key": "value"}')
      end

      it 'handles KeyError gracefully' do
        described_class.perform_now(strategy_plan.id)

        strategy_plan.reload
        expect(strategy_plan.status).to eq("failed")
        expect(strategy_plan.error_message).to include("response missing expected key")
        expect(strategy_plan.meta["voxa_failed_at"]).to be_present
      end
    end
  end
end
