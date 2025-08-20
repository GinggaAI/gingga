require 'rails_helper'

RSpec.describe Creas::VoxaContentService, type: :service do
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:strategy_plan) { create(:creas_strategy_plan, user: user, brand: brand, raw_payload: sample_noctua_payload) }
  let(:service) { described_class.new(strategy_plan: strategy_plan) }

  let(:sample_noctua_payload) do
    {
      "brand_name" => "Test Brand",
      "month" => "2025-08",
      "objective_of_the_month" => "awareness",
      "frequency_per_week" => 2,
      "post_types" => [ "Video", "Image" ],
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

    it "creates content items successfully" do
      expect { service.call }.to change(CreasContentItem, :count).by(1)

      created_item = CreasContentItem.last
      expect(created_item.content_id).to eq("20250819-w1-i1")
      expect(created_item.origin_id).to eq("202508-testbrand-w1-i1-C")
      expect(created_item.content_name).to eq("Test Content Item 1")
      expect(created_item.status).to eq("in_production")
      expect(created_item.pilar).to eq("C")
      expect(created_item.template).to eq("solo_avatars")
      expect(created_item.user).to eq(user)
      expect(created_item.brand).to eq(brand)
      expect(created_item.creas_strategy_plan).to eq(strategy_plan)
    end

    it "calls OpenAI with correct parameters" do
      expect(GinggaOpenAI::ChatClient).to receive(:new).with(
        user: user,
        model: "gpt-4o-mini",
        temperature: 0.5
      ).and_return(mock_chat_client)

      expect(mock_chat_client).to receive(:chat!).with(
        system: kind_of(String),
        user: kind_of(String)
      ).and_return(sample_voxa_response.to_json)

      service.call
    end

    it "handles idempotency - doesn't create duplicates on second run" do
      service.call
      initial_count = CreasContentItem.count

      # Run again with same data
      allow(mock_chat_client).to receive(:chat!).and_return(sample_voxa_response.to_json)
      service.call

      expect(CreasContentItem.count).to eq(initial_count)
      expect(CreasContentItem.where(content_id: "20250819-w1-i1").count).to eq(1)
    end

    it "updates existing items on second run" do
      service.call
      original_item = CreasContentItem.last
      original_updated_at = original_item.updated_at

      # Modify the response for second run
      modified_response = sample_voxa_response.deep_dup
      modified_response["items"][0]["content_name"] = "Updated Content Name"

      allow(mock_chat_client).to receive(:chat!).and_return(modified_response.to_json)

      travel_to(1.minute.from_now) do
        service.call
      end

      updated_item = CreasContentItem.find(original_item.id)
      expect(updated_item.content_name).to eq("Updated Content Name")
      expect(updated_item.updated_at).to be > original_updated_at
    end

    context "when OpenAI returns non-JSON" do
      before do
        allow(mock_chat_client).to receive(:chat!).and_return("This is not JSON")
      end

      it "raises an error" do
        expect { service.call }.to raise_error("Voxa returned non-JSON content")
      end

      it "doesn't create any content items" do
        expect { service.call rescue nil }.not_to change(CreasContentItem, :count)
      end
    end

    context "when Voxa response is missing items key" do
      before do
        allow(mock_chat_client).to receive(:chat!).and_return('{"no_items": []}')
      end

      it "raises a descriptive error" do
        expect { service.call }.to raise_error("Voxa response missing expected key: key not found: \"items\"")
      end
    end

    context "when individual item has invalid data" do
      let(:invalid_response) do
        invalid_item = sample_voxa_response["items"][0].except("id")
        { "items" => [ invalid_item ] }
      end

      before do
        allow(mock_chat_client).to receive(:chat!).and_return(invalid_response.to_json)
      end

      it "raises an error during persistence" do
        expect { service.call }.to raise_error(/missing expected key|key not found/)
      end

      it "doesn't create partial records due to transaction" do
        expect { service.call rescue nil }.not_to change(CreasContentItem, :count)
      end
    end
  end

  describe "#build_brand_context" do
    let(:brand_with_full_data) do
      brand = create(:brand,
        user: user,
        industry: "Technology",
        value_proposition: "Making tech accessible",
        mission: "Democratize technology",
        voice: "friendly",
        content_language: "en-US",
        banned_words_list: "inappropriate",
        guardrails: {}
      )
      create(:brand_channel, brand: brand, platform: :instagram, handle: "@test_insta")
      create(:brand_channel, brand: brand, platform: :tiktok, handle: "@test_tiktok")
      brand
    end

    it "builds correct brand context structure" do
      service_with_full_brand = described_class.new(strategy_plan: strategy_plan)
      service_with_full_brand.instance_variable_set(:@brand, brand_with_full_data)

      context = service_with_full_brand.send(:build_brand_context, brand_with_full_data)

      expected_context = {
        "brand" => {
          "industry" => "Technology",
          "value_proposition" => "Making tech accessible",
          "mission" => "Democratize technology",
          "voice" => "friendly",
          "priority_platforms" => [ "Instagram", "TikTok" ],
          "languages" => {
            "content_language" => "en-US",
            "account_language" => "en-US"
          },
          "guardrails" => brand_with_full_data.guardrails
        }
      }

      expect(context).to eq(expected_context)
    end

    it "handles empty guardrails" do
      brand_with_empty_guardrails = create(:brand, user: user, guardrails: {})
      service_with_empty_guardrails = described_class.new(strategy_plan: strategy_plan)
      service_with_empty_guardrails.instance_variable_set(:@brand, brand_with_empty_guardrails)

      context = service_with_empty_guardrails.send(:build_brand_context, brand_with_empty_guardrails)

      expect(context.dig("brand", "guardrails")).to eq(brand_with_empty_guardrails.guardrails)
    end
  end
end
