require 'rails_helper'

RSpec.describe CreasStrategyPlansController, type: :controller do
  describe 'format_plan_for_frontend' do
    let(:controller_instance) { described_class.new }

    let(:sample_plan) do
      double('CreasStrategyPlan',
        id: 'test-uuid',
        strategy_name: 'Test Strategy',
        month: '2024-01',
        objective_of_the_month: 'Increase engagement',
        frequency_per_week: 3,
        monthly_themes: [ 'Brand awareness', 'Product showcase' ],
        weekly_plan: [
          {
            "week_number" => 1,
            "theme" => "Awareness",
            "goal" => "Increase brand visibility",
            "content_pieces" => [
              {
                "day" => "Monday",
                "type" => "Post",
                "platform" => "instagram",
                "topic" => "Brand introduction"
              },
              {
                "day" => "Wednesday",
                "type" => "Reel",
                "platform" => "instagram",
                "topic" => "Behind the scenes"
              },
              {
                "day" => "Friday",
                "type" => "Post",
                "platform" => "instagram",
                "topic" => "Product highlight"
              }
            ]
          },
          {
            "week_number" => 2,
            "theme" => "Engagement",
            "content_pieces" => [
              {
                "day" => "Tuesday",
                "type" => "Reel",
                "platform" => "instagram"
              },
              {
                "day" => "Saturday",
                "type" => "Live",
                "platform" => "instagram"
              }
            ]
          }
        ]
      )
    end

    it 'formats plan data correctly for frontend consumption' do
      result = controller_instance.send(:format_plan_for_frontend, sample_plan)

      expect(result).to include(
        id: 'test-uuid',
        strategy_name: 'Test Strategy',
        month: '2024-01',
        objective_of_the_month: 'Increase engagement',
        frequency_per_week: 3,
        weeks: be_an(Array)
      )

      weeks = result[:weeks]
      expect(weeks.length).to eq(2)

      # Test week 1 formatting
      week_1 = weeks[0]
      expect(week_1).to include(
        week_number: 1,
        goal: 'Awareness',
        days: be_an(Array)
      )

      days = week_1[:days]
      expect(days.length).to eq(7) # Mon-Sun

      # Test specific day content
      monday = days.find { |d| d[:day] == 'Mon' }
      expect(monday).to eq({
        day: 'Mon',
        contents: [ 'Post' ]
      })

      wednesday = days.find { |d| d[:day] == 'Wed' }
      expect(wednesday).to eq({
        day: 'Wed',
        contents: [ 'Reel' ]
      })

      friday = days.find { |d| d[:day] == 'Fri' }
      expect(friday).to eq({
        day: 'Fri',
        contents: [ 'Post' ]
      })

      # Empty days should have empty contents
      tuesday = days.find { |d| d[:day] == 'Tue' }
      expect(tuesday).to eq({
        day: 'Tue',
        contents: []
      })

      # Test week 2
      week_2 = weeks[1]
      expect(week_2[:goal]).to eq('Engagement')

      week_2_days = week_2[:days]
      tuesday_w2 = week_2_days.find { |d| d[:day] == 'Tue' }
      expect(tuesday_w2[:contents]).to eq([ 'Reel' ])

      saturday_w2 = week_2_days.find { |d| d[:day] == 'Sat' }
      expect(saturday_w2[:contents]).to eq([ 'Live' ])
    end

    it 'handles empty weekly_plan gracefully' do
      empty_plan = double('CreasStrategyPlan',
        id: 'test-uuid',
        strategy_name: 'Empty Strategy',
        month: '2024-01',
        objective_of_the_month: 'Test',
        frequency_per_week: 3,
        monthly_themes: [],
        weekly_plan: []
      )

      result = controller_instance.send(:format_plan_for_frontend, empty_plan)
      expect(result[:weeks]).to eq([])
    end

    it 'handles malformed weekly_plan data' do
      malformed_plan = double('CreasStrategyPlan',
        id: 'test-uuid',
        strategy_name: 'Malformed Strategy',
        month: '2024-01',
        objective_of_the_month: 'Test',
        frequency_per_week: 3,
        monthly_themes: [],
        weekly_plan: [
          {
            "week_number" => 1
            # Missing theme/goal and content_pieces
          }
        ]
      )

      result = controller_instance.send(:format_plan_for_frontend, malformed_plan)

      expect(result[:weeks].length).to eq(1)
      week = result[:weeks][0]

      expect(week[:goal]).to be_a(String) # Should have fallback
      expect(week[:days].length).to eq(7)

      # All days should be empty since no content_pieces
      week[:days].each do |day|
        expect(day[:contents]).to eq([])
      end
    end
  end
end
