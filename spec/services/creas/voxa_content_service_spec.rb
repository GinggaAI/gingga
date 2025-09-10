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
              "recommended_template" => "only_avatars",
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
              "recommended_template" => "only_avatars",
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
          "template" => "only_avatars",
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

  describe "#initialize" do
    it "initializes with strategy plan and no target week" do
      service = described_class.new(strategy_plan: strategy_plan)

      expect(service.instance_variable_get(:@plan)).to eq(strategy_plan)
      expect(service.instance_variable_get(:@user)).to eq(user)
      expect(service.instance_variable_get(:@brand)).to eq(brand)
      expect(service.instance_variable_get(:@target_week)).to be_nil
    end

    it "initializes with strategy plan and target week" do
      service = described_class.new(strategy_plan: strategy_plan, target_week: 2)

      expect(service.instance_variable_get(:@plan)).to eq(strategy_plan)
      expect(service.instance_variable_get(:@user)).to eq(user)
      expect(service.instance_variable_get(:@brand)).to eq(brand)
      expect(service.instance_variable_get(:@target_week)).to eq(2)
    end

    it "initializes with associations from strategy plan" do
      service = described_class.new(strategy_plan: strategy_plan)

      expect(service.instance_variable_get(:@user)).to eq(strategy_plan.user)
      expect(service.instance_variable_get(:@brand)).to eq(strategy_plan.brand)
    end
  end

  describe "ServiceError" do
    describe "#initialize" do
      it "initializes with message only" do
        error = Creas::VoxaContentService::ServiceError.new("Test error")

        expect(error.message).to eq("Test error")
        expect(error.type).to eq(:generic)
        expect(error.user_message).to eq("Test error")
      end

      it "initializes with message, type, and user_message" do
        error = Creas::VoxaContentService::ServiceError.new(
          "Internal error",
          type: :processing_error,
          user_message: "Something went wrong"
        )

        expect(error.message).to eq("Internal error")
        expect(error.type).to eq(:processing_error)
        expect(error.user_message).to eq("Something went wrong")
      end

      it "uses message as user_message when user_message is not provided" do
        error = Creas::VoxaContentService::ServiceError.new("Test error", type: :validation)

        expect(error.user_message).to eq("Test error")
        expect(error.type).to eq(:validation)
      end
    end
  end

  describe "#call" do
    let(:mock_chat_client) { instance_double(GinggaOpenAI::ChatClient) }

    before do
      allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
      allow(mock_chat_client).to receive(:chat!).and_return(sample_voxa_response.to_json)
    end

    it "refreshes ActiveRecord instances at the beginning" do
      # Mock finding fresh plan
      fresh_plan = strategy_plan
      expect(CreasStrategyPlan).to receive(:find).with(strategy_plan.id).and_return(fresh_plan)
      expect(GenerateVoxaContentBatchJob).to receive(:perform_later)

      service.call

      # Verify instance variables were updated with fresh references
      expect(service.instance_variable_get(:@plan)).to eq(fresh_plan)
      expect(service.instance_variable_get(:@user)).to eq(fresh_plan.user)
      expect(service.instance_variable_get(:@brand)).to eq(fresh_plan.brand)
    end

    it "handles non-CreasStrategyPlan objects gracefully" do
      # Create service with a different object type
      non_plan_object = double("NonPlan", id: 123, user: user, brand: brand, status: "draft")
      service = described_class.new(strategy_plan: non_plan_object)
      expect(GenerateVoxaContentBatchJob).to receive(:perform_later)

      # Should not try to find fresh plan for non-CreasStrategyPlan objects
      expect(CreasStrategyPlan).not_to receive(:find)

      allow(non_plan_object).to receive(:creas_content_items).and_return(double(count: 0))
      allow(non_plan_object).to receive(:update!)
      allow(non_plan_object).to receive(:weekly_plan).and_return(nil)

      service.call
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

    it "queues GenerateVoxaContentBatchJob with correct parameters for full refinement" do
      expect(GenerateVoxaContentBatchJob).to receive(:perform_later).with(
        strategy_plan.id,
        1,  # target_batch_number
        4,  # total_batches
        kind_of(String)  # batch_id (UUID)
      )

      service.call
    end

    it "does not process content synchronously" do
      # Mock the batch job to prevent actual execution
      expect(GenerateVoxaContentBatchJob).to receive(:perform_later)

      expect { service.call }.not_to change(CreasContentItem, :count)
    end

    context "with target week specified" do
      let(:service) { described_class.new(strategy_plan: strategy_plan, target_week: 3) }

      it "processes single week refinement" do
        expect(GenerateVoxaContentBatchJob).to receive(:perform_later).with(
          strategy_plan.id,
          3,  # target_batch_number (week 3)
          1,  # total_batches (single week)
          kind_of(String)  # batch_id
        )

        result = service.call
        expect(result.status).to eq("pending")
      end
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

      it "logs warning when strategy is already processing" do
        strategy_plan.update!(status: :processing)
        expect(Rails.logger).to receive(:warn).with(/is already in processing status/)

        expect { service.call }.to raise_error(Creas::VoxaContentService::ServiceError)
      end

      it "handles standard errors and wraps them in ServiceError" do
        # Mock an error during execution after fresh plan is loaded
        allow(CreasStrategyPlan).to receive(:find).and_raise(StandardError, "Database error")

        expect(Rails.logger).to receive(:error).with(/Failed to start content refinement/)
        expect(Rails.logger).to receive(:error).with(/Error backtrace:/)

        expect { service.call }.to raise_error(Creas::VoxaContentService::ServiceError) do |error|
          expect(error.type).to eq(:processing_error)
          expect(error.user_message).to include("Failed to refine content")
          expect(error.message).to eq("Database error")
        end
      end

      it "handles errors with target week specified" do
        service = described_class.new(strategy_plan: strategy_plan, target_week: 2)
        allow(CreasStrategyPlan).to receive(:find).and_raise(StandardError, "Database error")

        expect { service.call }.to raise_error(Creas::VoxaContentService::ServiceError) do |error|
          expect(error.user_message).to include("Failed to refine week 2 content")
        end
      end

      it "re-raises ServiceError without modification" do
        # Mock a ServiceError during execution
        service_error = Creas::VoxaContentService::ServiceError.new("Custom error", type: :custom)
        allow(CreasStrategyPlan).to receive(:find).and_raise(service_error)

        expect(Rails.logger).to receive(:error).with("Voxa VoxaContentService: Custom error")

        expect { service.call }.to raise_error(service_error)
      end

      it "handles errors without backtrace gracefully" do
        error_without_backtrace = StandardError.new("No backtrace")
        allow(error_without_backtrace).to receive(:backtrace).and_return(nil)
        allow(CreasStrategyPlan).to receive(:find).and_raise(error_without_backtrace)

        expect(Rails.logger).to receive(:error).with(/Failed to start content refinement/)
        # Should not try to log backtrace when it's nil
        expect(Rails.logger).not_to receive(:error).with(/Error backtrace:/)

        expect { service.call }.to raise_error(Creas::VoxaContentService::ServiceError)
      end
    end
  end

  describe "private methods" do
    describe "#calculate_batches_needed" do
      it "always returns 4 batches for standard monthly strategy" do
        result = service.send(:calculate_batches_needed)
        expect(result).to eq(4)
      end


      it "handles strategy plan with no weekly plan" do
        allow(strategy_plan).to receive(:weekly_plan).and_return(nil)

        result = service.send(:calculate_batches_needed)
        expect(result).to eq(4)
      end

      it "handles strategy plan with custom weekly plan count" do
        custom_weekly_plan = [
          { "week" => 1 },
          { "week" => 2 },
          { "week" => 3 },
          { "week" => 4 },
          { "week" => 5 },
          { "week" => 6 }
        ]
        allow(strategy_plan).to receive(:weekly_plan).and_return(custom_weekly_plan)

        # Still returns 4 batches regardless of actual weekly plan count
        result = service.send(:calculate_batches_needed)
        expect(result).to eq(4)
      end
    end
  end

  describe "method visibility" do
    it "makes calculate_batches_needed private" do
      expect(service.private_methods).to include(:calculate_batches_needed)
    end
  end

  describe "integration with existing content items" do
    before do
      # Create some existing content items for the strategy plan with valid status
      create(:creas_content_item, creas_strategy_plan: strategy_plan, status: "draft")
      create(:creas_content_item, creas_strategy_plan: strategy_plan, status: "in_production")
    end

    it "processes with existing content items" do
      expect(strategy_plan.creas_content_items.count).to eq(2)
      expect(GenerateVoxaContentBatchJob).to receive(:perform_later)

      service.call
    end

    it "does not modify existing content items synchronously" do
      expect(GenerateVoxaContentBatchJob).to receive(:perform_later).once

      initial_count = strategy_plan.creas_content_items.count
      initial_draft_count = strategy_plan.creas_content_items.where(status: "draft").count

      service.call

      expect(strategy_plan.creas_content_items.reload.count).to eq(initial_count)
      expect(strategy_plan.creas_content_items.where(status: "draft").count).to eq(initial_draft_count)
    end
  end
end
