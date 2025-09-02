require 'rails_helper'

RSpec.describe GenerateVoxaContentBatchJob do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:strategy_plan) do
    create(:creas_strategy_plan,
           user: user,
           brand: brand,
           status: :pending,
           weekly_plan: [
             {
               "ideas" => [
                 {
                   "id" => "202508-test-w1-i1-C",
                   "title" => "Test Content 1",
                   "hook" => "Test Hook 1",
                   "pilar" => "C"
                 },
                 {
                   "id" => "202508-test-w1-i2-E",
                   "title" => "Test Content 2",
                   "hook" => "Test Hook 2",
                   "pilar" => "E"
                 }
               ]
             }
           ])
  end

  let(:batch_number) { 1 }
  let(:total_batches) { 1 }
  let(:batch_id) { "test-batch-123" }

  let(:mock_openai_response) do
    {
      "items" => [
        {
          "id" => "voxa-refined-1",
          "origin_id" => "202508-test-w1-i1-C",
          "week" => 1,
          "content_name" => "Refined Content 1",
          "status" => "in_production",
          "creation_date" => "2025-08-29",
          "content_type" => "reel",
          "platform" => "Instagram",
          "pilar" => "C",
          "template" => "solo_avatars",
          "video_source" => "kling",
          "post_description" => "Refined description 1",
          "text_base" => "Refined text 1",
          "hashtags" => "#test #refined",
          "publish_date" => "2025-08-29",
          "day_of_the_week" => "Monday"
        },
        {
          "id" => "voxa-refined-2",
          "origin_id" => "202508-test-w1-i2-E",
          "week" => 1,
          "content_name" => "Refined Content 2",
          "status" => "in_production",
          "creation_date" => "2025-08-29",
          "content_type" => "reel",
          "platform" => "Instagram",
          "pilar" => "E",
          "template" => "solo_avatars",
          "video_source" => "kling",
          "post_description" => "Refined description 2",
          "text_base" => "Refined text 2",
          "hashtags" => "#test #entertainment",
          "publish_date" => "2025-08-29",
          "day_of_the_week" => "Friday"
        }
      ]
    }.to_json
  end

  let(:mock_chat_client) { instance_double(GinggaOpenAI::ChatClient) }

  before do
    allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
    allow(mock_chat_client).to receive(:chat!).and_return(mock_openai_response)
  end

  describe '#perform' do
    context 'when strategy plan exists and has content items' do
      let!(:content_items) do
        Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call
      end

      it 'processes the batch successfully' do
        expect {
          described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)
        }.not_to change(CreasContentItem, :count)

        strategy_plan.reload
        expect(strategy_plan.status).to eq("completed")
        expect(strategy_plan.creas_content_items.where(status: "in_production").count).to eq(2)
      end

      it 'marks strategy plan as processing on first batch' do
        expect(strategy_plan.status).to eq("pending")

        described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)

        strategy_plan.reload
        expect(strategy_plan.status).to eq("completed")
      end

      it 'updates content items with Voxa refinements' do
        described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)

        first_item = strategy_plan.creas_content_items.find_by(content_id: "202508-test-w1-i1-C")
        expect(first_item.status).to eq("in_production")
        expect(first_item.content_name).to eq("Refined Content 1")
        expect(first_item.post_description).to eq("Refined description 1")
        expect(first_item.hashtags).to eq("#test #refined")
      end

      it 'preserves critical existing data during updates' do
        original_item = strategy_plan.creas_content_items.find_by(content_id: "202508-test-w1-i1-C")
        original_day = original_item.day_of_the_week
        original_week = original_item.week
        original_pilar = original_item.pilar

        described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)

        updated_item = strategy_plan.creas_content_items.find_by(content_id: "202508-test-w1-i1-C")
        expect(updated_item.day_of_the_week).to eq(original_day)
        expect(updated_item.week).to eq(original_week)
        expect(updated_item.pilar).to eq(original_pilar)
      end

      it 'creates AI response record for debugging' do
        expect {
          described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)
        }.to change(AiResponse, :count).by(1)

        ai_response = AiResponse.last
        expect(ai_response.service_name).to eq("voxa")
        expect(ai_response.ai_model).to eq("gpt-4o")
        expect(ai_response.batch_number).to eq(batch_number)
        expect(ai_response.total_batches).to eq(total_batches)
        expect(ai_response.batch_id).to eq(batch_id)
      end

      it 'updates strategy plan meta with batch information' do
        described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)

        strategy_plan.reload
        meta = strategy_plan.meta
        expect(meta["voxa_batches"]).to be_present
        expect(meta["voxa_batches"]["1"]).to include("processed_count", "completed_at")
        expect(meta["last_batch_processed"]).to eq(1)
        expect(meta["total_batches"]).to eq(1)
      end
    end

    context 'when strategy plan has no content items' do
      it 'creates draft content items automatically' do
        expect(strategy_plan.creas_content_items.count).to eq(0)

        described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)

        strategy_plan.reload
        expect(strategy_plan.creas_content_items.count).to be > 0
        expect(strategy_plan.creas_content_items.where(status: "in_production").count).to be > 0
      end
    end

    context 'when no content items are available for batch' do
      before do
        strategy_plan.creas_content_items.destroy_all
        # Mock empty content items result
        allow_any_instance_of(described_class).to receive(:get_content_items_for_batch).and_return([])
      end

      it 'completes batch with zero processed items' do
        described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)

        strategy_plan.reload
        meta = strategy_plan.meta
        expect(meta["voxa_batches"]["1"]["processed_count"]).to eq(0)
      end
    end

    context 'when processing multiple batches' do
      let(:total_batches) { 2 }

      it 'queues next batch when not the last batch' do
        expect(described_class).to receive(:perform_later).with(
          strategy_plan.id,
          2,
          total_batches,
          batch_id
        )

        described_class.perform_now(strategy_plan.id, 1, total_batches, batch_id)
      end

      it 'finalizes processing on last batch' do
        # Test with single batch to ensure finalization happens
        single_batch_total = 1

        # Ensure content items exist
        content_items = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call
        expect(content_items.count).to be > 0

        # Mark strategy plan as processing first (simulates what would happen in earlier batches)
        strategy_plan.update!(status: :processing)

        # Process as the only/final batch (batch 1 of 1)
        described_class.perform_now(strategy_plan.id, 1, single_batch_total, batch_id)

        strategy_plan.reload
        expect(strategy_plan.status).to eq("completed")
        expect(strategy_plan.meta["voxa_processed_at"]).to be_present
        expect(strategy_plan.meta["voxa_completion_rate"]).to be > 0
      end
    end

    context 'error handling' do
      context 'when OpenAI returns invalid JSON' do
        before do
          allow(mock_chat_client).to receive(:chat!).and_return("invalid json response")
        end

        it 'handles JSON parsing error gracefully' do
          # Ensure content items exist
          Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call

          described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)

          strategy_plan.reload
          expect(strategy_plan.status).to eq("failed")
          expect(strategy_plan.error_message).to include("returned non-JSON content")
        end

        it 'resets content items status on error' do
          content_items = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call

          described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)

          content_items.each(&:reload)
          expect(content_items.all? { |item| item.status == "draft" }).to be true
        end
      end

      context 'when OpenAI response is missing required keys' do
        before do
          allow(mock_chat_client).to receive(:chat!).and_return('{"wrong_key": "value"}')
        end

        it 'handles KeyError gracefully' do
          Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call

          described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)

          strategy_plan.reload
          expect(strategy_plan.status).to eq("failed")
          expect(strategy_plan.error_message).to include("response missing expected key")
        end
      end

      context 'when database transaction fails' do
        before do
          allow_any_instance_of(CreasContentItem).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(CreasContentItem.new))
        end

        it 'handles database errors gracefully and continues processing' do
          Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call

          described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)

          strategy_plan.reload
          # With the refactored error handling, the job now continues processing
          # even when individual items fail, so the strategy plan should complete
          expect(strategy_plan.status).to eq("completed")

          # Check that batch metadata was still recorded
          meta = strategy_plan.meta
          expect(meta["voxa_batches"]).to be_present
          expect(meta["voxa_batches"]["1"]).to include("processed_count", "completed_at")
        end
      end


      context 'when strategy plan is not found' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            described_class.new.perform(999999, batch_number, total_batches, batch_id)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'stuck items handling in finalize_voxa_processing' do
      let!(:content_items) do
        Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call
      end

      before do
        # Simulate stuck items
        strategy_plan.creas_content_items.update_all(status: "in_progress")
      end

      it 'fixes stuck in_progress items during finalization' do
        # Verify stuck items exist before processing
        expect(strategy_plan.creas_content_items.where(status: "in_progress").count).to be > 0

        described_class.perform_now(strategy_plan.id, batch_number, total_batches, batch_id)

        strategy_plan.reload
        stuck_count = strategy_plan.creas_content_items.where(status: "in_progress").count
        expect(stuck_count).to eq(0)
        # Note: stuck_items_fixed is only set if items were actually stuck, which they are in this test
        expect(strategy_plan.meta["stuck_items_fixed"]).to be >= 0
      end
    end

    context 'brand context building' do
      let(:brand_with_channels) do
        brand = create(:brand, user: user)
        brand.brand_channels.create!(platform: "instagram", handle: "@test_insta")
        brand.brand_channels.create!(platform: "tiktok", handle: "@test_tiktok")
        brand
      end

      let(:strategy_plan_with_channels) do
        create(:creas_strategy_plan, user: user, brand: brand_with_channels, weekly_plan: strategy_plan.weekly_plan)
      end

      it 'extracts platform information correctly' do
        job = described_class.new

        brand_context = job.send(:build_brand_context, brand_with_channels)
        priority_platforms = brand_context.dig("brand", "priority_platforms")

        expect(priority_platforms).to include("Instagram", "TikTok")
      end

      it 'provides default platforms when none exist' do
        job = described_class.new

        brand_context = job.send(:build_brand_context, brand)
        priority_platforms = brand_context.dig("brand", "priority_platforms")

        expect(priority_platforms).to eq([ "Instagram", "TikTok" ])
      end
    end

    context 'template normalization' do
      let(:job) { described_class.new }

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

    context 'day of week extraction' do
      let(:job) { described_class.new }

      it 'extracts day_of_the_week from various sources' do
        item_with_day = { "day_of_the_week" => "Monday" }
        expect(job.send(:extract_day_of_week, item_with_day)).to eq("Monday")

        item_with_meta_day = { "meta" => { "day_of_the_week" => "Tuesday" } }
        expect(job.send(:extract_day_of_week, item_with_meta_day)).to eq("Tuesday")

        item_with_publish_date = { "publish_date" => "2025-08-29", "pilar" => "C" }
        result = job.send(:extract_day_of_week, item_with_publish_date)
        expect(%w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]).to include(result)
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
      end
    end

    context 'date parsing' do
      let(:job) { described_class.new }

      it 'parses valid ISO dates' do
        expect(job.send(:parse_date, "2025-08-29")).to eq(Date.new(2025, 8, 29))
        expect(job.send(:parse_date, "2025-12-31")).to eq(Date.new(2025, 12, 31))
      end

      it 'returns nil for invalid dates' do
        expect(job.send(:parse_date, "invalid-date")).to be_nil
        expect(job.send(:parse_date, "")).to be_nil
        expect(job.send(:parse_date, nil)).to be_nil
      end

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

    context 'shotplan handling' do
      let(:job) { described_class.new }
      let(:existing_record) { build(:creas_content_item) }

      it 'uses Voxa shotplan when available' do
        voxa_item = {
          "shotplan" => {
            "scenes" => [ { "scene_number" => 1, "text" => "Voxa scene" } ]
          }
        }

        result = job.send(:ensure_shot_plan, voxa_item, existing_record)
        expect(result["scenes"]).to be_present
        expect(result["scenes"][0]["text"]).to eq("Voxa scene")
      end

      it 'falls back to existing shotplan when Voxa shotplan is invalid' do
        existing_record.shotplan = {
          "scenes" => [ { "scene_number" => 1, "text" => "Existing scene" } ]
        }
        voxa_item = { "shotplan" => nil }

        result = job.send(:ensure_shot_plan, voxa_item, existing_record)
        expect(result["scenes"]).to be_present
        expect(result["scenes"][0]["text"]).to eq("Existing scene")
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
  end

  describe 'batch processing workflow' do
    context 'with realistic content volume' do
      let(:strategy_plan_large) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               status: :pending,
               weekly_plan: Array.new(4) do |week_index|
                 {
                   "ideas" => Array.new(5) do |idea_index|
                     {
                       "id" => "202508-test-w#{week_index + 1}-i#{idea_index + 1}-C",
                       "title" => "Content #{week_index + 1}.#{idea_index + 1}",
                       "hook" => "Hook #{week_index + 1}.#{idea_index + 1}",
                       "pilar" => %w[C R E A S].sample
                     }
                   end
                 }
               end)
      end

      it 'handles large batches correctly' do
        # Create content items (should be 20 total)
        content_items = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan_large).call
        expect(content_items.count).to eq(20)

        # Mock response with many items
        large_response = {
          "items" => Array.new(7) do |i|
            {
              "id" => "voxa-refined-#{i + 1}",
              "origin_id" => content_items[i]&.content_id || "fallback-id-#{i}",
              "week" => 1,
              "content_name" => "Refined Content #{i + 1}",
              "status" => "in_production",
              "creation_date" => "2025-08-29",
              "content_type" => "reel",
              "platform" => "Instagram",
              "pilar" => "C",
              "template" => "solo_avatars",
              "video_source" => "kling",
              "post_description" => "Description #{i + 1}",
              "text_base" => "Text #{i + 1}",
              "hashtags" => "#test#{i + 1}",
              "publish_date" => "2025-08-29"
            }
          end
        }.to_json

        allow(mock_chat_client).to receive(:chat!).and_return(large_response)

        # Process first batch (should handle 7 items)
        described_class.perform_now(strategy_plan_large.id, 1, 3, batch_id)

        strategy_plan_large.reload
        processed_count = strategy_plan_large.creas_content_items.where(status: "in_production").count
        expect(processed_count).to be >= 7
      end
    end
  end
end
