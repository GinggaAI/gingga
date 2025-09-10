require 'rails_helper'

RSpec.describe Creas::WeeklyDistributionValidator do
  describe '.validate_weekly_distribution!' do
    let(:base_payload) do
      {
        "month" => "2025-12",
        "brand_slug" => "testbrand",
        "frequency_per_week" => 3,
        "weekly_plan" => [
          {
            "week_number" => 1,
            "ideas" => [
              {
                "id" => "202512-testbrand-w1-i1-C",
                "title" => "Test Content 1",
                "hook" => "Hook 1",
                "description" => "Description 1",
                "platform" => "Instagram Reels",
                "pilar" => "C",
                "recommended_template" => "only_avatars",
                "video_source" => "none"
              }
            ]
          },
          {
            "week_number" => 2,
            "ideas" => []
          },
          {
            "week_number" => 3,
            "ideas" => [
              {
                "id" => "202512-testbrand-w3-i1-E",
                "title" => "Test Content 3",
                "pilar" => "E"
              },
              {
                "id" => "202512-testbrand-w3-i2-A",
                "title" => "Test Content 4",
                "pilar" => "A"
              },
              {
                "id" => "202512-testbrand-w3-i3-R",
                "title" => "Test Content 5",
                "pilar" => "R"
              },
              {
                "id" => "202512-testbrand-w3-i4-S",
                "title" => "Test Content 6",
                "pilar" => "S"
              }
            ]
          },
          {
            "week_number" => 4,
            "ideas" => [
              {
                "id" => "202512-testbrand-w4-i1-C",
                "title" => "Test Content 7",
                "pilar" => "C"
              },
              {
                "id" => "202512-testbrand-w4-i2-E",
                "title" => "Test Content 8",
                "pilar" => "E"
              }
            ]
          }
        ]
      }
    end

    context 'when weekly_plan is valid and matches frequency' do
      let(:valid_payload) do
        base_payload.merge(
          "weekly_plan" => [
            { "ideas" => Array.new(3) { |i| { "id" => "w1-i#{i+1}", "title" => "Content #{i+1}" } } },
            { "ideas" => Array.new(3) { |i| { "id" => "w2-i#{i+1}", "title" => "Content #{i+1}" } } },
            { "ideas" => Array.new(3) { |i| { "id" => "w3-i#{i+1}", "title" => "Content #{i+1}" } } },
            { "ideas" => Array.new(3) { |i| { "id" => "w4-i#{i+1}", "title" => "Content #{i+1}" } } }
          ]
        )
      end

      it 'returns the payload unchanged' do
        result = described_class.validate_weekly_distribution!(valid_payload)
        expect(result).to eq(valid_payload)
      end

      it 'logs the final distribution' do
        expect(Rails.logger).to receive(:info).with("Weekly distribution validated: 3-3-3-3 (total: 12)")
        described_class.validate_weekly_distribution!(valid_payload)
      end
    end

    context 'when weekly_plan has invalid structure' do
      context 'when weekly_plan is not an array' do
        let(:invalid_payload) { base_payload.merge("weekly_plan" => "invalid") }

        it 'returns the original payload' do
          result = described_class.validate_weekly_distribution!(invalid_payload)
          expect(result).to eq(invalid_payload)
        end

        it 'logs a warning' do
          expect(Rails.logger).to receive(:warn).with("Invalid weekly_plan structure: expected 4 weeks, got 7")
          described_class.validate_weekly_distribution!(invalid_payload)
        end
      end

      context 'when weekly_plan has wrong number of weeks' do
        let(:short_payload) { base_payload.merge("weekly_plan" => [ { "ideas" => [] }, { "ideas" => [] } ]) }

        it 'returns the original payload' do
          result = described_class.validate_weekly_distribution!(short_payload)
          expect(result).to eq(short_payload)
        end

        it 'logs a warning with actual length' do
          expect(Rails.logger).to receive(:warn).with("Invalid weekly_plan structure: expected 4 weeks, got 2")
          described_class.validate_weekly_distribution!(short_payload)
        end
      end

      context 'when weekly_plan is nil' do
        let(:nil_payload) { base_payload.merge("weekly_plan" => nil) }

        it 'returns the original payload' do
          result = described_class.validate_weekly_distribution!(nil_payload)
          expect(result).to eq(nil_payload)
        end

        it 'logs a warning' do
          expect(Rails.logger).to receive(:warn).with("Invalid weekly_plan structure: expected 4 weeks, got ")
          described_class.validate_weekly_distribution!(nil_payload)
        end
      end
    end

    context 'when frequency_per_week is invalid' do
      context 'when frequency_per_week is not an integer' do
        let(:invalid_freq_payload) { base_payload.merge("frequency_per_week" => "invalid") }

        it 'returns the original payload' do
          result = described_class.validate_weekly_distribution!(invalid_freq_payload)
          expect(result).to eq(invalid_freq_payload)
        end

        it 'logs a warning' do
          expect(Rails.logger).to receive(:warn).with("Invalid frequency_per_week: invalid")
          described_class.validate_weekly_distribution!(invalid_freq_payload)
        end
      end

      context 'when frequency_per_week is zero or negative' do
        let(:zero_freq_payload) { base_payload.merge("frequency_per_week" => 0) }

        it 'returns the original payload' do
          result = described_class.validate_weekly_distribution!(zero_freq_payload)
          expect(result).to eq(zero_freq_payload)
        end

        it 'logs a warning' do
          expect(Rails.logger).to receive(:warn).with("Invalid frequency_per_week: 0")
          described_class.validate_weekly_distribution!(zero_freq_payload)
        end
      end

      context 'when frequency_per_week is nil' do
        let(:nil_freq_payload) { base_payload.merge("frequency_per_week" => nil) }

        it 'returns the original payload' do
          result = described_class.validate_weekly_distribution!(nil_freq_payload)
          expect(result).to eq(nil_freq_payload)
        end

        it 'logs a warning' do
          expect(Rails.logger).to receive(:warn).with("Invalid frequency_per_week: ")
          described_class.validate_weekly_distribution!(nil_freq_payload)
        end
      end
    end

    context 'when weeks have insufficient ideas' do
      it 'duplicates existing ideas to meet frequency requirement' do
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)

        result = described_class.validate_weekly_distribution!(base_payload)

        # Week 1 should have 3 ideas (1 original + 2 duplicated)
        week1_ideas = result["weekly_plan"][0]["ideas"]
        expect(week1_ideas.length).to eq(3)
        expect(week1_ideas[0]["title"]).to eq("Test Content 1")
        expect(week1_ideas[1]["title"]).to include("Test Content 1")
        expect(week1_ideas[1]["title"]).to include("Auto-generated")
        expect(week1_ideas[2]["title"]).to include("Test Content 1")
        expect(week1_ideas[2]["title"]).to include("Auto-generated")

        # Verify IDs are unique
        expect(week1_ideas[0]["id"]).to eq("202512-testbrand-w1-i1-C")
        expect(week1_ideas[1]["id"]).to eq("202512-testbrand-w1-i2-C")
        expect(week1_ideas[2]["id"]).to eq("202512-testbrand-w1-i3-C")
      end

      it 'creates minimal ideas when no existing ideas are available' do
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)

        result = described_class.validate_weekly_distribution!(base_payload)

        # Week 2 has no original ideas, should create 3 minimal ones
        week2_ideas = result["weekly_plan"][1]["ideas"]
        expect(week2_ideas.length).to eq(3)

        week2_ideas.each_with_index do |idea, index|
          expect(idea["id"]).to match(/^202512-testbrand-w2-i#{index + 1}-[CREAS]$/)
          expect(idea["title"]).to eq("Week 2 Content #{index + 1}")
          expect(idea["hook"]).to eq("Engaging hook")
          expect(idea["description"]).to eq("Auto-generated content idea")
          expect(idea["platform"]).to eq("Instagram Reels")
          expect(idea["pilar"]).to be_in(%w[C R E A S])
          expect(idea["recommended_template"]).to eq("only_avatars")
          expect(idea["video_source"]).to eq("none")
        end
      end

      it 'combines duplication and minimal creation when needed' do
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)

        # Week 4 has 2 ideas, needs 1 more
        result = described_class.validate_weekly_distribution!(base_payload)

        week4_ideas = result["weekly_plan"][3]["ideas"]
        expect(week4_ideas.length).to eq(3)

        # First two should be original
        expect(week4_ideas[0]["title"]).to eq("Test Content 7")
        expect(week4_ideas[1]["title"]).to eq("Test Content 8")

        # Third should be duplicated
        expect(week4_ideas[2]["title"]).to be_in([ "Test Content 7 (Auto-generated 3)", "Test Content 8 (Auto-generated 3)" ])
      end

      it 'logs warnings for weeks that need fixing' do
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)

        described_class.validate_weekly_distribution!(base_payload)

        expect(Rails.logger).to have_received(:warn).with("Week 1: expected 3 ideas, got 1")
        expect(Rails.logger).to have_received(:warn).with("Week 2: expected 3 ideas, got 0")
        expect(Rails.logger).to have_received(:warn).with("Week 4: expected 3 ideas, got 2")
        expect(Rails.logger).to have_received(:info).with("Weekly distribution validated: 3-3-3-3 (total: 12)")
      end
    end

    context 'when weeks have excess ideas' do
      let(:excess_payload) do
        base_payload.merge("frequency_per_week" => 2)
      end

      it 'trims excess ideas to match frequency requirement' do
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)

        result = described_class.validate_weekly_distribution!(excess_payload)

        # Week 3 originally has 4 ideas, should be trimmed to 2
        week3_ideas = result["weekly_plan"][2]["ideas"]
        expect(week3_ideas.length).to eq(2)

        # Should keep the first 2 ideas
        expect(week3_ideas[0]["title"]).to eq("Test Content 3")
        expect(week3_ideas[1]["title"]).to eq("Test Content 4")
      end

      it 'logs warnings for weeks that are trimmed' do
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)

        described_class.validate_weekly_distribution!(excess_payload)

        expect(Rails.logger).to have_received(:warn).with("Week 1: expected 2 ideas, got 1")
        expect(Rails.logger).to have_received(:warn).with("Week 2: expected 2 ideas, got 0")
        expect(Rails.logger).to have_received(:warn).with("Week 3: expected 2 ideas, got 4")
        # Week 4 originally has 2 ideas which matches frequency_per_week=2, so no warning expected
        expect(Rails.logger).to have_received(:info).with("Weekly distribution validated: 2-2-2-2 (total: 8)")
      end
    end

    context 'when weeks have missing ideas array' do
      let(:missing_ideas_payload) do
        base_payload.merge(
          "weekly_plan" => [
            { "week_number" => 1 }, # Missing "ideas" key
            { "week_number" => 2, "ideas" => nil }, # Nil ideas
            { "week_number" => 3, "ideas" => [ { "id" => "test", "title" => "Test" } ] },
            { "week_number" => 4, "ideas" => [] }
          ]
        )
      end

      it 'treats missing or nil ideas as empty arrays' do
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)

        result = described_class.validate_weekly_distribution!(missing_ideas_payload)

        # All weeks should have 3 ideas after validation
        result["weekly_plan"].each_with_index do |week, index|
          expect(week["ideas"].length).to eq(3), "Week #{index + 1} should have 3 ideas"
        end
      end
    end

    context 'edge cases' do
      context 'when payload has missing month or brand_slug' do
        let(:missing_brand_payload) do
          base_payload.merge("brand_slug" => nil, "month" => nil)
        end

        it 'still processes but creates IDs with nil values' do
          allow(Rails.logger).to receive(:warn)
          allow(Rails.logger).to receive(:info)

          result = described_class.validate_weekly_distribution!(missing_brand_payload)

          # Week 2 will have auto-generated content with nil brand_slug
          week2_ideas = result["weekly_plan"][1]["ideas"]
          expect(week2_ideas.first["id"]).to match(/^--w2-i1-[CREAS]$/)
        end
      end

      context 'when original idea has no ID' do
        let(:no_id_payload) do
          base_payload.merge(
            "weekly_plan" => [
              { "ideas" => [ { "title" => "No ID Content" } ] },
              { "ideas" => [] },
              { "ideas" => [] },
              { "ideas" => [] }
            ]
          )
        end

        it 'handles duplication of ideas without IDs gracefully' do
          allow(Rails.logger).to receive(:warn)
          allow(Rails.logger).to receive(:info)

          result = described_class.validate_weekly_distribution!(no_id_payload)

          week1_ideas = result["weekly_plan"][0]["ideas"]
          expect(week1_ideas.length).to eq(3)

          # First idea should remain unchanged
          expect(week1_ideas[0]["title"]).to eq("No ID Content")
          expect(week1_ideas[0]["id"]).to be_nil

          # Duplicated ideas should have modified titles
          expect(week1_ideas[1]["title"]).to include("No ID Content")
          expect(week1_ideas[1]["title"]).to include("Auto-generated")
          expect(week1_ideas[2]["title"]).to include("No ID Content")
          expect(week1_ideas[2]["title"]).to include("Auto-generated")
        end
      end
    end

    context 'integration with logging' do
      it 'provides comprehensive logging for complex scenarios' do
        # Mock Rails.logger to capture all messages
        log_messages = []
        allow(Rails.logger).to receive(:warn) { |msg| log_messages << msg }
        allow(Rails.logger).to receive(:info) { |msg| log_messages << msg }

        described_class.validate_weekly_distribution!(base_payload)

        expect(log_messages).to include(
          "Week 1: expected 3 ideas, got 1",
          "Week 2: expected 3 ideas, got 0",
          "Week 4: expected 3 ideas, got 2",
          "Weekly distribution validated: 3-3-3-3 (total: 12)"
        )
        # Week 3 has the expected number (4 ideas, but not trimmed since frequency is 3)
        # So we expect at least 4 messages, but may have more if Week 3 is also logged
        expect(log_messages.length).to be >= 4
      end
    end
  end
end
