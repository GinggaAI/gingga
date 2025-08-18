require 'rails_helper'

RSpec.describe Creas::StrategyPlanFormatter do
  let(:strategy_plan) do
    create(:creas_strategy_plan,
           strategy_name: "Test Strategy",
           month: "2025-08",
           objective_of_the_month: "Increase brand awareness",
           frequency_per_week: 3,
           monthly_themes: [ "theme1", "theme2" ],
           weekly_plan: weekly_plan_data)
  end

  let(:weekly_plan_data) do
    [
      {
        "theme" => "Awareness Week",
        "content_pieces" => [
          {
            "day" => "Monday",
            "type" => "Educational Post"
          },
          {
            "day" => "Wednesday",
            "type" => "Behind the Scenes"
          }
        ]
      },
      {
        "goal" => "Engagement Week",
        "posts" => [
          {
            "day" => "Tuesday",
            "type" => "Interactive Content"
          }
        ]
      }
    ]
  end

  describe '.call' do
    it 'returns formatted strategy plan data' do
      result = described_class.call(strategy_plan)

      expect(result).to include(
        id: strategy_plan.id,
        strategy_name: "Test Strategy",
        month: "2025-08",
        objective_of_the_month: "Increase brand awareness",
        frequency_per_week: 3,
        monthly_themes: [ "theme1", "theme2" ]
      )
    end

    it 'formats weekly plan data correctly' do
      result = described_class.call(strategy_plan)

      expect(result[:weeks]).to be_an(Array)
      expect(result[:weeks].length).to eq(2)

      first_week = result[:weeks][0]
      expect(first_week).to include(
        week_number: 1,
        goal: "Awareness Week"
      )
      expect(first_week[:days]).to be_an(Array)
      expect(first_week[:days].length).to eq(7)
    end

    it 'handles nil plan gracefully' do
      result = described_class.call(nil)
      expect(result).to eq({ error: "Plan not found" })
    end
  end

  describe '#call' do
    subject { described_class.new(strategy_plan) }

    context 'with valid strategy plan' do
      it 'extracts basic plan information' do
        result = subject.call

        expect(result[:id]).to eq(strategy_plan.id)
        expect(result[:strategy_name]).to eq("Test Strategy")
        expect(result[:month]).to eq("2025-08")
        expect(result[:objective_of_the_month]).to eq("Increase brand awareness")
        expect(result[:frequency_per_week]).to eq(3)
        expect(result[:monthly_themes]).to eq([ "theme1", "theme2" ])
      end

      it 'formats weeks with correct structure' do
        result = subject.call

        expect(result[:weeks]).to be_an(Array)
        expect(result[:weeks].length).to eq(2)

        first_week = result[:weeks][0]
        expect(first_week[:week_number]).to eq(1)
        expect(first_week[:goal]).to eq("Awareness Week")
        expect(first_week[:days]).to be_an(Array)
        expect(first_week[:days].length).to eq(7)

        # Check day structure
        monday = first_week[:days].find { |day| day[:day] == "Mon" }
        expect(monday[:contents]).to eq([ "Educational Post" ])

        wednesday = first_week[:days].find { |day| day[:day] == "Wed" }
        expect(wednesday[:contents]).to eq([ "Behind the Scenes" ])

        # Empty days should have empty contents
        sunday = first_week[:days].find { |day| day[:day] == "Sun" }
        expect(sunday[:contents]).to eq([])
      end

      it 'handles second week with different data structure' do
        result = subject.call

        second_week = result[:weeks][1]
        expect(second_week[:week_number]).to eq(2)
        expect(second_week[:goal]).to eq("Engagement Week")

        tuesday = second_week[:days].find { |day| day[:day] == "Tue" }
        expect(tuesday[:contents]).to eq([ "Interactive Content" ])
      end
    end

    context 'with weekly_plan as non-array' do
      let(:strategy_plan) do
        create(:creas_strategy_plan, weekly_plan: { invalid: "data" })
      end

      it 'returns empty weeks array' do
        result = subject.call
        expect(result[:weeks]).to eq([])
      end
    end

    context 'with empty weekly_plan' do
      let(:strategy_plan) do
        create(:creas_strategy_plan, weekly_plan: [])
      end

      it 'returns empty weeks array' do
        result = subject.call
        expect(result[:weeks]).to eq([])
      end
    end
  end

  describe 'private methods' do
    subject { described_class.new(strategy_plan) }

    describe '#extract_goal_from_week' do
      it 'extracts theme when present' do
        week_data = { "theme" => "Custom Theme" }
        goal = subject.send(:extract_goal_from_week, week_data)
        expect(goal).to eq("Custom Theme")
      end

      it 'falls back to goal when theme not present' do
        week_data = { "goal" => "Custom Goal" }
        goal = subject.send(:extract_goal_from_week, week_data)
        expect(goal).to eq("Custom Goal")
      end

      it 'returns default goal when neither theme nor goal present' do
        week_data = {}
        goal = subject.send(:extract_goal_from_week, week_data)
        expect([ "Awareness", "Engagement", "Launch", "Conversion" ]).to include(goal)
      end
    end

    describe '#normalize_day_name' do
      it 'normalizes full day names correctly' do
        expect(subject.send(:normalize_day_name, "Monday")).to eq("Mon")
        expect(subject.send(:normalize_day_name, "Tuesday")).to eq("Tue")
        expect(subject.send(:normalize_day_name, "Wednesday")).to eq("Wed")
        expect(subject.send(:normalize_day_name, "Thursday")).to eq("Thu")
        expect(subject.send(:normalize_day_name, "Friday")).to eq("Fri")
        expect(subject.send(:normalize_day_name, "Saturday")).to eq("Sat")
        expect(subject.send(:normalize_day_name, "Sunday")).to eq("Sun")
      end

      it 'handles capitalization variations' do
        expect(subject.send(:normalize_day_name, "monday")).to eq("Mon")
        expect(subject.send(:normalize_day_name, "TUESDAY")).to eq("Tue")
      end

      it 'handles unknown day names by taking first 3 characters' do
        expect(subject.send(:normalize_day_name, "Someday")).to eq("Som")
      end

      it 'returns nil for nil input' do
        expect(subject.send(:normalize_day_name, nil)).to be_nil
      end

      it 'returns nil for empty string' do
        expect(subject.send(:normalize_day_name, "")).to be_nil
      end
    end

    describe '#group_content_by_day' do
      let(:content_pieces) do
        [
          { "day" => "Monday", "type" => "Post 1" },
          { "day" => "Monday", "type" => "Post 2" },
          { "day" => "Wednesday", "type" => "Post 3" },
          { "day" => nil, "type" => "Invalid Post" },
          { "day" => "Tuesday" } # No type specified
        ]
      end

      it 'groups content by normalized day names' do
        result = subject.send(:group_content_by_day, content_pieces)

        expect(result["Mon"]).to eq([ "Post 1", "Post 2" ])
        expect(result["Wed"]).to eq([ "Post 3" ])
        expect(result["Tue"]).to eq([ "Post" ])
        expect(result["Thu"]).to be_nil
      end

      it 'skips content with nil day' do
        result = subject.send(:group_content_by_day, content_pieces)
        expect(result.values.flatten).not_to include("Invalid Post")
      end

      it 'uses default "Post" type when type not specified' do
        result = subject.send(:group_content_by_day, content_pieces)
        expect(result["Tue"]).to eq([ "Post" ])
      end
    end

    describe '#extract_days_from_week' do
      let(:week_data) do
        {
          "content_pieces" => [
            { "day" => "Monday", "type" => "Educational" },
            { "day" => "Friday", "type" => "Fun" }
          ]
        }
      end

      it 'returns all 7 days of the week' do
        result = subject.send(:extract_days_from_week, week_data)

        expect(result.length).to eq(7)
        days = result.map { |day| day[:day] }
        expect(days).to eq(%w[Mon Tue Wed Thu Fri Sat Sun])
      end

      it 'assigns content to correct days' do
        result = subject.send(:extract_days_from_week, week_data)

        monday = result.find { |day| day[:day] == "Mon" }
        expect(monday[:contents]).to eq([ "Educational" ])

        friday = result.find { |day| day[:day] == "Fri" }
        expect(friday[:contents]).to eq([ "Fun" ])

        tuesday = result.find { |day| day[:day] == "Tue" }
        expect(tuesday[:contents]).to eq([])
      end

      it 'handles "posts" key as alternative to "content_pieces"' do
        week_data = {
          "posts" => [
            { "day" => "Tuesday", "type" => "Post" }
          ]
        }

        result = subject.send(:extract_days_from_week, week_data)
        tuesday = result.find { |day| day[:day] == "Tue" }
        expect(tuesday[:contents]).to eq([ "Post" ])
      end

      it 'handles empty content gracefully' do
        week_data = {}
        result = subject.send(:extract_days_from_week, week_data)

        expect(result.length).to eq(7)
        result.each do |day|
          expect(day[:contents]).to eq([])
        end
      end
    end
  end
end
