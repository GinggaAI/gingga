require 'rails_helper'

RSpec.describe 'Weekly Distribution Consistency', type: :integration do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:month) { "2025-08" }

  let(:brief_3_per_week) do
    {
      brand_name: brand.name,
      brand_slug: brand.slug,
      industry: brand.industry,
      objective_of_the_month: "awareness",
      frequency_per_week: 3
    }
  end

  describe 'Noctua strategy generation for 3 posts per week' do
    it 'should generate exactly 3 posts per week across all 4 weeks' do
      # Mock the AI to return a realistic but potentially inconsistent response
      mock_ai_response = {
        "brand_name" => brand.name,
        "brand_slug" => brand.slug,
        "month" => month,
        "objective_of_the_month" => "awareness",
        "frequency_per_week" => 3,
        "content_distribution" => {
          "C" => {
            "goal" => "Increase brand awareness",
            "ideas" => [
              {
                "id" => "202508-#{brand.slug}-C-w1-i1",
                "title" => "Content Week 1",
                "pilar" => "C",
                "platform" => "Instagram Reels"
              },
              {
                "id" => "202508-#{brand.slug}-C-w2-i1",
                "title" => "Content Week 2",
                "pilar" => "C",
                "platform" => "Instagram Reels"
              }
            ]
          },
          "E" => {
            "goal" => "Entertainment",
            "ideas" => [
              {
                "id" => "202508-#{brand.slug}-E-w3-i1",
                "title" => "Entertainment Week 3",
                "pilar" => "E",
                "platform" => "Instagram Reels"
              }
            ]
          }
        },
        "weekly_plan" => [
          {
            "week" => 1,
            "publish_cadence" => 3,
            "ideas" => [
              {
                "id" => "202508-#{brand.slug}-w1-i1-C",
                "title" => "Week 1 Content 1",
                "pilar" => "C",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              },
              {
                "id" => "202508-#{brand.slug}-w1-i2-E",
                "title" => "Week 1 Content 2",
                "pilar" => "E",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              },
              {
                "id" => "202508-#{brand.slug}-w1-i3-A",
                "title" => "Week 1 Content 3",
                "pilar" => "A",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              }
            ]
          },
          {
            "week" => 2,
            "publish_cadence" => 3,
            "ideas" => [
              {
                "id" => "202508-#{brand.slug}-w2-i1-C",
                "title" => "Week 2 Content 1",
                "pilar" => "C",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              },
              {
                "id" => "202508-#{brand.slug}-w2-i2-R",
                "title" => "Week 2 Content 2",
                "pilar" => "R",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              }
              # INTENTIONALLY MISSING 3rd item to simulate the bug
            ]
          },
          {
            "week" => 3,
            "publish_cadence" => 3,
            "ideas" => [
              {
                "id" => "202508-#{brand.slug}-w3-i1-S",
                "title" => "Week 3 Content 1",
                "pilar" => "S",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              },
              {
                "id" => "202508-#{brand.slug}-w3-i2-E",
                "title" => "Week 3 Content 2",
                "pilar" => "E",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              },
              {
                "id" => "202508-#{brand.slug}-w3-i3-C",
                "title" => "Week 3 Content 3",
                "pilar" => "C",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              }
            ]
          },
          {
            "week" => 4,
            "publish_cadence" => 3,
            "ideas" => [
              {
                "id" => "202508-#{brand.slug}-w4-i1-A",
                "title" => "Week 4 Content 1",
                "pilar" => "A",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              },
              {
                "id" => "202508-#{brand.slug}-w4-i2-S",
                "title" => "Week 4 Content 2",
                "pilar" => "S",
                "platform" => "Instagram Reels",
                "recommended_template" => "solo_avatars",
                "video_source" => "none"
              }
              # INTENTIONALLY MISSING 3rd item to simulate the bug
            ]
          }
        ]
      }.to_json

      mock_client = instance_double(GinggaOpenAI::ChatClient)
      allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:chat!).and_return(mock_ai_response)

      # Create the strategy
      service = Creas::NoctuaStrategyService.new(user: user, brief: brief_3_per_week, brand: brand, month: month)
      strategy_plan = service.call_sync

      # Check the raw AI response was saved (this will show the original inconsistent response)
      ai_response = AiResponse.by_service("noctua").recent.first
      expect(ai_response).to be_present
      expect(ai_response.response_summary).to include("3/week target")

      # Check the raw response (should show the problem)
      parsed_response = ai_response.parsed_response
      raw_weekly_plan = parsed_response["weekly_plan"]
      raw_week_counts = raw_weekly_plan.map { |week| week["ideas"]&.count || 0 }

      # Check that the final strategy plan was corrected by validation
      final_weekly_plan = strategy_plan.weekly_plan
      final_week_counts = final_weekly_plan.map { |week| week["ideas"]&.count || 0 }

      # The final strategy plan should be corrected to have consistent distribution
      expect(final_week_counts).to all(eq(3)), "Expected all weeks to have 3 items after validation, but got: #{final_week_counts.join('-')}"
      expect(final_week_counts.sum).to eq(12), "Expected total of 12 items (3x4), got #{final_week_counts.sum}"
    end

    it 'should be detected by AiResponse model analysis' do
      # Mock inconsistent response
      mock_response = {
        "frequency_per_week" => 3,
        "weekly_plan" => [
          { "week" => 1, "ideas" => [ {}, {}, {} ] },  # 3 items ✓
          { "week" => 2, "ideas" => [ {}, {} ] },      # 2 items ✗
          { "week" => 3, "ideas" => [ {}, {}, {} ] },  # 3 items ✓
          { "week" => 4, "ideas" => [ {}, {} ] }       # 2 items ✗
        ]
      }

      ai_response = AiResponse.new(
        user: user,
        service_name: "noctua",
        ai_model: "gpt-4o",
        prompt_version: "test",
        raw_response: mock_response.to_json
      )

      summary = ai_response.response_summary
      expect(summary).to eq("3/week target, actual: 3-2-3-2 (total: 10)")
    end
  end
end
