require 'rails_helper'

RSpec.describe GenerateNoctuaStrategyBatchJob do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:strategy_plan) { create(:creas_strategy_plan, user: user, brand: brand, status: :pending) }
  let(:brief) { "Create a social media strategy focused on increasing brand awareness" }
  let(:batch_number) { 1 }
  let(:total_batches) { 4 }
  let(:batch_id) { "test-batch-123" }

  let(:mock_openai_response) do
    {
      "ideas" => [
        {
          "id" => "202508-test-w1-i1-C",
          "title" => "Educational Video 1",
          "hook" => "Did you know?",
          "description" => "Share industry insights",
          "platform" => "Instagram Reels",
          "pilar" => "C",
          "recommended_template" => "only_avatars",
          "video_source" => "none"
        },
        {
          "id" => "202508-test-w1-i2-E",
          "title" => "Entertainment Video 1",
          "hook" => "Fun fact!",
          "description" => "Engaging entertainment content",
          "platform" => "TikTok",
          "pilar" => "E",
          "recommended_template" => "avatar_and_video",
          "video_source" => "kling"
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
    context 'basic batch processing functionality' do
      it 'processes a batch successfully and creates necessary records' do
        expect(strategy_plan.status).to eq("pending")

        expect {
          perform_enqueued_jobs do
            described_class.perform_now(strategy_plan.id, brief, batch_number, total_batches, batch_id)
          end
        }.to change(AiResponse, :count).by(4) # Creates AI responses for all 4 batches

        strategy_plan.reload
        expect(strategy_plan.status).to eq("completed") # Final status after all batches
      end
    end

    context 'successful batch processing' do
      it 'creates AI response records for all batches' do
        expect {
          perform_enqueued_jobs do
            described_class.perform_now(strategy_plan.id, brief, batch_number, total_batches, batch_id)
          end
        }.to change(AiResponse, :count).by(4)

        # Check the first AI response record
        ai_responses = AiResponse.order(:created_at)
        first_response = ai_responses.first
        expect(first_response.service_name).to eq("noctua")
        expect(first_response.ai_model).to eq("gpt-4o")
        expect(first_response.prompt_version).to eq("noctua-batch-v1")
        expect(first_response.batch_number).to eq(1)
        expect(first_response.total_batches).to eq(total_batches)
        expect(first_response.batch_id).to eq(batch_id)
        expect(first_response.user).to eq(user)
        expect(first_response.metadata["strategy_plan_id"]).to eq(strategy_plan.id)
        expect(first_response.metadata["brief"]).to eq(brief)
      end

      it 'processes and merges weekly plan data correctly' do
        perform_enqueued_jobs do
          described_class.perform_now(strategy_plan.id, brief, batch_number, total_batches, batch_id)
        end

        strategy_plan.reload
        weekly_plan = strategy_plan.weekly_plan

        expect(weekly_plan).to be_present
        expect(weekly_plan[0]).to include("ideas")
        expect(weekly_plan[0]["ideas"]).to be_an(Array)
        expect(weekly_plan[0]["ideas"].length).to eq(2)

        first_idea = weekly_plan[0]["ideas"][0]
        expect(first_idea["id"]).to eq("202508-test-w1-i1-C")
        expect(first_idea["title"]).to eq("Educational Video 1")
        expect(first_idea["pilar"]).to eq("C")
      end

      it 'updates batch processing metadata for final batch' do
        perform_enqueued_jobs do
          described_class.perform_now(strategy_plan.id, brief, batch_number, total_batches, batch_id)
        end

        strategy_plan.reload
        meta = strategy_plan.meta

        expect(meta).to be_present
        expect(meta["noctua_batches"]).to be_present
        expect(meta["noctua_batches"]["1"]).to include("batch_id", "processed_at", "total_ideas")
        expect(meta["last_batch_processed"]).to eq(4) # All batches processed
        expect(meta["total_batches"]).to eq(4)
      end
    end

    context 'when processing final batch' do
      let(:batch_number) { 4 }

      it 'finalizes strategy plan and creates content items' do
        # Set up previous batches in meta
        strategy_plan.update!(
          status: :processing,
          meta: {
            "noctua_batches" => {
              "1" => { "batch_id" => batch_id, "processed_at" => 1.hour.ago, "total_ideas" => 2, "ideas" => [] },
              "2" => { "batch_id" => batch_id, "processed_at" => 30.minutes.ago, "total_ideas" => 2, "ideas" => [] },
              "3" => { "batch_id" => batch_id, "processed_at" => 15.minutes.ago, "total_ideas" => 2, "ideas" => [] }
            },
            "last_batch_processed" => 3,
            "total_batches" => 4
          }
        )

        expect {
          described_class.perform_now(strategy_plan.id, brief, batch_number, total_batches, batch_id)
        }.to change(CreasContentItem, :count)

        strategy_plan.reload
        expect(strategy_plan.status).to eq("completed")
        expect(strategy_plan.meta["assembly_completed_at"]).to be_present
        expect(strategy_plan.meta["last_batch_processed"]).to eq(4)
      end

      it 'creates content items automatically via ContentItemInitializerService' do
        # Set up a complete weekly plan
        strategy_plan.update!(
          weekly_plan: [
            {
              "ideas" => [
                {
                  "id" => "202508-test-w1-i1-C",
                  "title" => "Test Content 1",
                  "hook" => "Test Hook 1",
                  "pilar" => "C"
                }
              ]
            }
          ]
        )

        described_class.perform_now(strategy_plan.id, brief, batch_number, total_batches, batch_id)

        strategy_plan.reload
        expect(strategy_plan.creas_content_items.count).to be > 0
        expect(strategy_plan.creas_content_items.first.status).to eq("draft")
      end
    end

    context 'when processing middle batch' do
      let(:batch_number) { 2 }

      it 'queues next batch job' do
        expect(described_class).to receive(:perform_later).with(
          strategy_plan.id,
          brief,
          3,
          total_batches,
          batch_id
        )

        described_class.perform_now(strategy_plan.id, brief, batch_number, total_batches, batch_id)
      end
    end

    context 'error handling' do
      context 'when OpenAI returns invalid JSON' do
        before do
          allow(mock_chat_client).to receive(:chat!).and_return("invalid json response")
        end

        it 'handles JSON parsing error gracefully' do
          described_class.perform_now(strategy_plan.id, brief, batch_number, total_batches, batch_id)

          strategy_plan.reload
          expect(strategy_plan.status).to eq("failed")
          expect(strategy_plan.error_message).to include("non-JSON content")
          expect(strategy_plan.meta["failed_at"]).to be_present
        end
      end

      context 'when OpenAI response is missing required keys' do
        before do
          # Mock the service to fail only on the first batch
          call_count = 0
          allow(mock_chat_client).to receive(:chat!) do
            call_count += 1
            if call_count == 1
              '{"wrong_key": "value"}'
            else
              mock_openai_response
            end
          end
        end

        it 'handles missing keys by using empty ideas array' do
          perform_enqueued_jobs do
            described_class.perform_now(strategy_plan.id, brief, batch_number, total_batches, batch_id)
          end

          strategy_plan.reload
          # The job should complete successfully even with missing keys by using empty arrays
          expect(strategy_plan.status).to eq("completed")
          expect(strategy_plan.weekly_plan).to be_present
        end
      end

      context 'when strategy plan is not found' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            described_class.new.perform(999999, brief, batch_number, total_batches, batch_id)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when unexpected error occurs' do
        before do
          allow(mock_chat_client).to receive(:chat!).and_raise(StandardError.new("Unexpected error"))
        end

        it 'handles general errors gracefully' do
          described_class.perform_now(strategy_plan.id, brief, batch_number, total_batches, batch_id)

          strategy_plan.reload
          expect(strategy_plan.status).to eq("failed")
          expect(strategy_plan.error_message).to include("Unexpected error")
          expect(strategy_plan.meta["failed_at"]).to be_present
        end
      end
    end

    context 'prompt building' do
      let(:job) { described_class.new }

      describe '#build_batch_system_prompt' do
        it 'builds system prompt with batch context' do
          prompt = job.send(:build_batch_system_prompt, 2, 4)

          expect(prompt).to include("WEEK 2 of a 4-week strategy")
          expect(prompt).to include("Focus ONLY on week 2 content ideas")
          expect(prompt).to be_a(String)
        end

        it 'handles first batch correctly' do
          prompt = job.send(:build_batch_system_prompt, 1, 4)

          expect(prompt).to include("WEEK 1 of a 4-week strategy")
          expect(prompt).to include("Focus ONLY on week 1 content ideas")
        end

        it 'handles final batch correctly' do
          prompt = job.send(:build_batch_system_prompt, 4, 4)

          expect(prompt).to include("WEEK 4 of a 4-week strategy")
          expect(prompt).to include("Focus ONLY on week 4 content ideas")
        end

        it 'includes base noctua system prompt' do
          prompt = job.send(:build_batch_system_prompt, 1, 4)

          expect(prompt).to include("You are CREAS Strategist (Noctua)")
          expect(prompt).to include("Design a monthly social content plan")
        end
      end

      describe '#build_batch_user_prompt' do
        it 'builds user prompt with brief and batch context' do
          prompt = job.send(:build_batch_user_prompt, brief, 2, 4, strategy_plan)

          expect(prompt).to include(brief)
          expect(prompt).to include("week 2")
          expect(prompt).to include("WEEK 2 SPECIFIC REQUIREMENTS")
          expect(prompt).to include("Maximum 7 content items")
          expect(prompt).to be_a(String)
        end

        it 'includes batch-specific format instructions' do
          prompt = job.send(:build_batch_user_prompt, brief, 1, 4, strategy_plan)

          expect(prompt).to include('"week": 1')
          expect(prompt).to include('"ideas": [')
          expect(prompt).to include("Return the response in this exact format")
        end

        it 'includes existing content context when available' do
          # Create some existing content items
          create(:creas_content_item,
                 creas_strategy_plan: strategy_plan,
                 batch_number: 1,
                 content_name: "Existing Item",
                 pilar: "C",
                 platform: "instagram")

          prompt = job.send(:build_batch_user_prompt, brief, 2, 4, strategy_plan)

          expect(prompt).to include("EXISTING CONTENT FROM PREVIOUS WEEKS")
          expect(prompt).to include("Existing Item")
        end
      end

      # Note: build_brand_context method doesn't exist in the actual implementation
      # The brand context is built inline within build_batch_user_prompt
    end

    context 'batch processing methods' do
      let(:job) { described_class.new }

      describe '#get_existing_content_context' do
        let!(:existing_items) do
          [
            create(:creas_content_item,
                   creas_strategy_plan: strategy_plan,
                   batch_number: 1,
                   content_name: "First Item",
                   pilar: "C",
                   platform: "instagram"),
            create(:creas_content_item,
                   creas_strategy_plan: strategy_plan,
                   batch_number: 1,
                   content_name: "Second Item",
                   pilar: "E",
                   platform: "tiktok")
          ]
        end

        it 'returns context from previous batches' do
          context = job.send(:get_existing_content_context, strategy_plan, 2)

          expect(context).to include("First Item")
          expect(context).to include("Second Item")
          expect(context).to include("Week 1")
        end

        it 'returns empty string when no previous content exists' do
          context = job.send(:get_existing_content_context, strategy_plan, 1)

          expect(context).to eq("")
        end

        it 'truncates long context to 1000 characters' do
          # Create many items to exceed 1000 characters
          20.times do |i|
            create(:creas_content_item,
                   creas_strategy_plan: strategy_plan,
                   batch_number: 1,
                   content_name: "Very Long Content Item Name That Will Make Context Very Long #{i}",
                   pilar: "C",
                   platform: "instagram")
          end

          context = job.send(:get_existing_content_context, strategy_plan, 2)

          expect(context.length).to be <= 1003  # 1000 + "..."
          expect(context).to end_with("...") if context.length > 1000
        end

        it 'filters only previous batches' do
          # Create items in batch 1 and batch 3
          create(:creas_content_item,
                 creas_strategy_plan: strategy_plan,
                 batch_number: 1,
                 content_name: "Batch 1 Item",
                 pilar: "C",
                 platform: "instagram")
          create(:creas_content_item,
                 creas_strategy_plan: strategy_plan,
                 batch_number: 3,
                 content_name: "Batch 3 Item",
                 pilar: "E",
                 platform: "tiktok")

          # Context for batch 2 should only include batch 1
          context = job.send(:get_existing_content_context, strategy_plan, 2)

          expect(context).to include("Batch 1 Item")
          expect(context).not_to include("Batch 3 Item")
        end
      end

      describe '#process_batch_results' do
        it 'processes standard batch response format' do
          parsed_response = {
            "week" => 1,
            "ideas" => [
              {
                "id" => "202508-test-w1-i1-C",
                "title" => "Test Content",
                "pilar" => "C"
              }
            ]
          }

          job.send(:process_batch_results, strategy_plan, parsed_response, 1, 4, batch_id)

          strategy_plan.reload
          meta = strategy_plan.meta
          expect(meta["noctua_batches"]).to be_present
          expect(meta["noctua_batches"]["1"]["ideas"].count).to eq(1)
        end

        it 'handles full strategy response in first batch' do
          parsed_response = {
            "strategy_name" => "Test Strategy",
            "objective_of_the_month" => "awareness",
            "weekly_plan" => [
              {
                "week_number" => 1,
                "ideas" => [
                  {
                    "id" => "202508-test-w1-i1-C",
                    "title" => "Test Content",
                    "pilar" => "C"
                  }
                ]
              }
            ]
          }

          job.send(:process_batch_results, strategy_plan, parsed_response, 1, 4, batch_id)

          strategy_plan.reload
          meta = strategy_plan.meta
          expect(meta["strategy_info_from_ai"]).to be_present
          expect(meta["strategy_info_from_ai"]["strategy_name"]).to eq("Test Strategy")
        end
      end

      describe '#finalize_strategy_plan' do
        before do
          strategy_plan.update!(
            meta: {
              "noctua_batches" => {
                "1" => { "batch_id" => batch_id, "week" => 1, "ideas" => [], "processed_at" => Time.current, "total_ideas" => 2 },
                "2" => { "batch_id" => batch_id, "week" => 2, "ideas" => [], "processed_at" => Time.current, "total_ideas" => 2 }
              },
              "last_batch_processed" => 2,
              "total_batches" => 2
            }
          )
        end

        it 'assembles weekly plan from batches when no full plan from AI' do
          job.send(:finalize_strategy_plan, strategy_plan, batch_id)

          strategy_plan.reload
          expect(strategy_plan.status).to eq("completed")
          expect(strategy_plan.weekly_plan).to be_present
          expect(strategy_plan.weekly_plan.count).to eq(2)
        end
      end

      describe '#initialize_content_items' do
        it 'handles service errors gracefully' do
          service_instance = double("service_instance")
          allow(Creas::ContentItemInitializerService).to receive(:new).and_return(service_instance)
          allow(service_instance).to receive(:call).and_raise(StandardError.new("Service error"))

          expect(Rails.logger).to receive(:error).with(/Failed to initialize content items/)
          expect(Rails.logger).to receive(:error).with(/Error backtrace/)

          expect { job.send(:initialize_content_items, strategy_plan) }.not_to raise_error
        end
      end

      describe '#broadcast_completion' do
      end
    end

    context 'batch completion logic' do
      let(:job) { described_class.new }

      describe '#handle_batch_error' do
        it 'marks strategy plan as failed with error details' do
          job.send(:handle_batch_error, strategy_plan, "Test error", 2)

          strategy_plan.reload
          expect(strategy_plan.status).to eq("failed")
          expect(strategy_plan.error_message).to include("Batch 2 failed: Test error")
          expect(strategy_plan.meta["failed_batch"]).to eq(2)
          expect(strategy_plan.meta["batch_error"]).to eq("Test error")
          expect(strategy_plan.meta["failed_at"]).to be_present
        end
      end

      describe '#handle_incomplete_brief_error' do
        it 'handles incomplete brief errors specifically' do
          job.send(:handle_incomplete_brief_error, strategy_plan, "Brief is incomplete", 1)

          strategy_plan.reload
          expect(strategy_plan.status).to eq("failed")
          expect(strategy_plan.error_message).to include("incomplete brief")
          expect(strategy_plan.meta["error_type"]).to eq("incomplete_brief")
          expect(strategy_plan.meta["failed_batch"]).to eq(1)
          expect(strategy_plan.meta["failed_at"]).to be_present
        end
      end
    end
  end
end
