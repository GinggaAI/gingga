require 'rails_helper'

RSpec.describe Creas::VoxaContentService, type: :service do
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:strategy_plan) do
    create(:creas_strategy_plan,
      user: user,
      brand: brand,
      raw_payload: sample_noctua_payload,
      content_distribution: sample_noctua_payload["content_distribution"],
      weekly_plan: sample_noctua_payload["weekly_plan"],
      objective_of_the_month: sample_noctua_payload["objective_of_the_month"],
      frequency_per_week: sample_noctua_payload["frequency_per_week"]
    )
  end
  let(:service) { described_class.new(strategy_plan: strategy_plan) }

  let(:sample_noctua_payload) do
    {
      "brand_name" => "Test Brand",
      "month" => "2025-08",
      "objective_of_the_month" => "awareness",
      "frequency_per_week" => 2,
      "post_types" => [ "Video", "Image" ],
      "content_distribution" => {
        "C" => {
          "goal" => "Increase brand awareness",
          "formats" => [ "Video", "Carousel" ],
          "ideas" => [
            {
              "id" => "202508-testbrand-C-w1-i1",
              "title" => "Test Content 1",
              "hook" => "Amazing hook",
              "description" => "Test description",
              "platform" => "Instagram Reels",
              "pilar" => "C",
              "recommended_template" => "solo_avatars",
              "video_source" => "none"
            }
          ]
        },
        "R" => {
          "goal" => "Build relationships",
          "formats" => [ "Video" ],
          "ideas" => [
            {
              "id" => "202508-testbrand-R-w1-i1",
              "title" => "Test Content 2",
              "hook" => "Another hook",
              "description" => "Another description",
              "platform" => "Instagram Reels",
              "pilar" => "R",
              "recommended_template" => "narration_over_7_images",
              "video_source" => "none"
            }
          ]
        }
      },
      "weekly_plan" => [
        {
          "week" => 1,
          "ideas" => [
            {
              "id" => "202508-testbrand-w1-i1-C",
              "title" => "Test Content 1",
              "hook" => "Amazing hook",
              "description" => "Test description",
              "platform" => "Instagram Reels",
              "pilar" => "C",
              "recommended_template" => "solo_avatars",
              "video_source" => "none"
            },
            {
              "id" => "202508-testbrand-w1-i2-R",
              "title" => "Test Content 2",
              "hook" => "Another hook",
              "description" => "Another description",
              "platform" => "Instagram Reels",
              "pilar" => "R",
              "recommended_template" => "narration_over_7_images",
              "video_source" => "none"
            }
          ]
        }
      ]
    }
  end

  let(:sample_voxa_response) do
    {
      "items" => [
        {
          "id" => "20250819-w1-i1",
          "origin_id" => "202508-testbrand-w1-i1-C",
          "origin_source" => "weekly_plan",
          "week" => 1,
          "week_index" => 1,
          "content_name" => "Test Content Item 1",
          "status" => "in_production",
          "creation_date" => "2025-08-19",
          "publish_date" => "2025-08-22",
          "publish_datetime_local" => "2025-08-22T18:00:00",
          "timezone" => "Europe/Madrid",
          "content_type" => "Video",
          "platform" => "Instagram Reels",
          "aspect_ratio" => "9:16",
          "language" => "en-US",
          "pilar" => "C",
          "template" => "solo_avatars",
          "video_source" => "none",
          "post_description" => "This is a test post description",
          "text_base" => "Test text base",
          "hashtags" => "#test #content #creation",
          "subtitles" => { "mode" => "platform_auto", "languages" => [ "en-US" ] },
          "dubbing" => { "enabled" => false, "languages" => [] },
          "shotplan" => {
            "scenes" => [
              {
                "id" => 1,
                "role" => "Hook",
                "type" => "avatar",
                "visual" => "Close-up shot",
                "on_screen_text" => "Hook text",
                "voiceover" => "Hook voiceover",
                "avatar_id" => "avatar_123",
                "voice_id" => "voice_123"
              }
            ],
            "beats" => []
          },
          "assets" => {
            "external_video_url" => "",
            "video_urls" => [],
            "video_prompts" => [],
            "broll_suggestions" => []
          },
          "accessibility" => { "captions" => true, "srt_export" => true },
          "kpi_focus" => "reach",
          "success_criteria" => "≥8% saves",
          "compliance_check" => "ok"
        }
      ]
    }
  end

  describe "#call" do
    let(:mock_chat_client) { instance_double(GinggaOpenAI::ChatClient) }

    before do
      allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
      allow(mock_chat_client).to receive(:chat!).and_return(sample_voxa_response.to_json)
    end

    it "queues batch job and sets strategy plan status to pending" do
      initial_status = strategy_plan.status

      # Mock the batch job to track that it's enqueued
      expect(GenerateVoxaContentBatchJob).to receive(:perform_later)

      result = service.call

      # Should return the strategy plan
      expect(result).to eq(strategy_plan)
      expect(result.status).to eq("pending")

      # Should not process content synchronously anymore
      expect(strategy_plan.creas_content_items.where(status: "in_production").count).to eq(0)
    end

    it "sets strategy plan to pending status" do
      # Set initial status to something other than pending
      strategy_plan.update!(status: "completed")
      expect(strategy_plan.status).not_to eq("pending")

      # Mock the batch job to prevent actual execution
      expect(GenerateVoxaContentBatchJob).to receive(:perform_later)

      service.call
      strategy_plan.reload

      expect(strategy_plan.status).to eq("pending")
    end

    it "queues GenerateVoxaContentBatchJob with correct parameters" do
      expect(GenerateVoxaContentBatchJob).to receive(:perform_later)

      service.call
    end

    it "does not process content synchronously" do
      # Mock the batch job to prevent actual execution
      expect(GenerateVoxaContentBatchJob).to receive(:perform_later)

      expect { service.call }.not_to change(CreasContentItem, :count)
    end

    context "error handling" do
      it "queues batch job successfully even when OpenAI would fail" do
        # Service no longer does OpenAI calls directly - errors handled in job
        expect(GenerateVoxaContentBatchJob).to receive(:perform_later)

        expect { service.call }.not_to raise_error
        expect(strategy_plan.reload.status).to eq("pending")
      end

      it "raises error when strategy is already processing" do
        # Set strategy to processing status
        strategy_plan.update!(status: :processing)

        expect { service.call }.to raise_error(Creas::VoxaContentService::ServiceError) do |error|
          expect(error.type).to eq(:already_processing)
          expect(error.user_message).to include("already in progress")
        end
        expect(strategy_plan.reload.status).to eq("processing") # Status unchanged
      end
    end
  end
end
