require 'rails_helper'

RSpec.describe 'Frequency Per Week Content Generation', type: :integration do
  include ActiveJob::TestHelper
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let!(:audience) { create(:audience, brand: brand) }
  let!(:product) { create(:product, brand: brand) }
  let!(:brand_channel) { create(:brand_channel, brand: brand) }

  let(:month) { '2025-08' }

  # Mock OpenAI response with correct structure for different frequencies
  def mock_openai_response_for_frequency(frequency)
    weekly_ideas = []

    (1..4).each do |week|
      ideas = []
      frequency.times do |idx|
        ideas << {
          "id" => "202508-#{brand.slug}-w#{week}-i#{idx + 1}-C",
          "status" => "draft",
          "title" => "Content idea #{week}-#{idx + 1}",
          "hook" => "Hook for week #{week}, idea #{idx + 1}",
          "description" => "Description for content",
          "platform" => "Instagram Reels",
          "pilar" => "C",
          "recommended_template" => "only_avatars",
          "video_source" => "none",
          "visual_notes" => "Visual notes",
          "assets_hints" => {},
          "kpi_focus" => "reach",
          "success_criteria" => "≥1000 views",
          "beats_outline" => [ "Hook", "Value", "CTA" ],
          "cta" => "Follow for more",
          "repurpose_to" => [],
          "language_variants" => []
        }
      end

      weekly_ideas << {
        "week" => week,
        "publish_cadence" => frequency,
        "ideas" => ideas
      }
    end

    {
      "brand_name" => brand.name,
      "brand_slug" => brand.slug,
      "strategy_name" => "Test Strategy",
      "month" => month,
      "objective_of_the_month" => "awareness",
      "frequency_per_week" => frequency,
      "content_distribution" => { "C" => { "goal" => "Growth" } },
      "weekly_plan" => weekly_ideas,
      "remix_duet_plan" => { "rationale" => "Test" },
      "publish_windows_local" => {},
      "monthly_themes" => [ "test theme" ]
    }.to_json
  end

  def mock_batch_response_for_week(week, frequency, brand)
    ideas = []
    frequency.times do |idx|
      ideas << {
        "id" => "202508-#{brand.slug}-w#{week}-i#{idx + 1}-C",
        "status" => "draft",
        "title" => "Content idea #{week}-#{idx + 1}",
        "hook" => "Hook for week #{week}, idea #{idx + 1}",
        "description" => "Description for content",
        "platform" => "Instagram Reels",
        "pilar" => "C",
        "recommended_template" => "only_avatars",
        "video_source" => "none",
        "visual_notes" => "Visual notes",
        "assets_hints" => {},
        "kpi_focus" => "reach",
        "success_criteria" => "≥1000 views",
        "beats_outline" => [ "Hook", "Value", "CTA" ],
        "cta" => "Follow for more",
        "repurpose_to" => [],
        "language_variants" => []
      }
    end

    {
      "week" => week,
      "ideas" => ideas
    }.to_json
  end

  describe 'with different frequencies' do
    [ 3, 4, 5, 7 ].each do |frequency|
      context "when frequency_per_week is #{frequency}" do
        let(:strategy_params) do
          {
            objective_of_the_month: 'awareness',
            frequency_per_week: frequency,
            monthly_themes: [ 'test theme' ]
          }
        end

        before do
          # Mock OpenAI to return the correct response for each batch call
          # Since batch processing calls OpenAI once per week, we need to mock each call
          call_count = 0
          allow_any_instance_of(GinggaOpenAI::ChatClient)
            .to receive(:chat!) do
              call_count += 1
              mock_batch_response_for_week(call_count, frequency, brand)
            end
        end

        it "generates exactly #{frequency * 4} content ideas (#{frequency} per week × 4 weeks)" do
          result = nil

          perform_enqueued_jobs do
            result = CreateStrategyService.call(
              user: user,
              brand: brand,
              month: month,
              strategy_params: strategy_params
            )
          end

          expect(result.success?).to be true

          # Reload the strategy plan to get the completed data after job execution
          strategy = result.plan.reload
          expect(strategy.frequency_per_week).to eq(frequency)

          # Count total ideas across all weeks
          total_ideas = strategy.weekly_plan.sum { |week| week['ideas'].size }
          expected_total = frequency * 4

          expect(total_ideas).to eq(expected_total),
            "Expected #{expected_total} total ideas (#{frequency}/week × 4 weeks), but got #{total_ideas}"

          # Verify each week has the correct number of ideas
          strategy.weekly_plan.each do |week_data|
            week_ideas_count = week_data['ideas'].size
            expect(week_ideas_count).to eq(frequency),
              "Week #{week_data['week']} should have #{frequency} ideas, but has #{week_ideas_count}"
            expect(week_data['publish_cadence']).to eq(frequency)
          end
        end
      end
    end
  end

  describe 'prompt validation' do
    it 'includes clear frequency instructions in the system prompt' do
      system_prompt = Creas::Prompts.noctua_system

      # Check that the prompt includes the frequency rule
      expect(system_prompt).to include('frequency_per_week × 4 weeks')
      expect(system_prompt).to include('3/week = 12 total')
      expect(system_prompt).to include('4/week = 16 total')
      expect(system_prompt).to include('CRITICAL: weekly_plan must contain exactly 4 weeks, each with exactly frequency_per_week ideas')
    end
  end
end
