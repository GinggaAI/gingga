require 'rails_helper'

RSpec.describe Planning::WeeklyPlansBuilder do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  describe '.call' do
    context 'when no strategy is provided' do
      it 'returns fallback plans' do
        plans = described_class.call(nil)

        expect(plans).to be_an(Array)
        expect(plans.size).to eq(1)
        expect(plans.first[:status]).to eq(:needs_strategy)
        expect(plans.first[:message]).to include("Create your first AI-powered strategy")
      end
    end

    context 'when strategy has empty weekly_plan' do
      let(:strategy) { create(:creas_strategy_plan, user: user, brand: brand, weekly_plan: []) }

      it 'returns fallback plans' do
        plans = described_class.call(strategy)

        expect(plans.size).to eq(1)
        expect(plans.first[:status]).to eq(:needs_strategy)
      end
    end

    context 'when strategy has valid weekly_plan' do
      let(:weekly_plan) do
        [
          {
            "week" => 1,
            "publish_cadence" => 3,
            "ideas" => [
              {
                "id" => "202508-brand-w1-i1-C",
                "status" => "draft",
                "title" => "Growth Content",
                "pilar" => "C"
              },
              {
                "id" => "202508-brand-w1-i2-R",
                "status" => "published",
                "title" => "Retention Content",
                "pilar" => "R"
              },
              {
                "id" => "202508-brand-w1-i3-E",
                "status" => "in_production",
                "title" => "Engagement Content",
                "pilar" => "E"
              }
            ]
          },
          {
            "week" => 2,
            "publish_cadence" => 3,
            "ideas" => [
              {
                "id" => "202508-brand-w2-i1-A",
                "status" => "ready_for_review",
                "title" => "Activation Content",
                "pilar" => "A"
              },
              {
                "id" => "202508-brand-w2-i2-S",
                "status" => "approved",
                "title" => "Satisfaction Content",
                "pilar" => "S"
              }
            ]
          }
        ]
      end

      let(:strategy) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               month: "2025-08",
               frequency_per_week: 3,
               weekly_plan: weekly_plan)
      end

      it 'builds correct number of week plans' do
        plans = described_class.call(strategy)

        expect(plans.size).to eq(2)
        expect(plans.map { |p| p[:week_number] }).to eq([ 1, 2 ])
      end

      it 'correctly counts content per week' do
        plans = described_class.call(strategy)

        expect(plans[0][:content_count]).to eq(3)
        expect(plans[1][:content_count]).to eq(2)
      end

      it 'extracts goals from CREAS pillars' do
        plans = described_class.call(strategy)

        expect(plans[0][:goals]).to contain_exactly(:growth, :retention, :engagement)
        expect(plans[1][:goals]).to contain_exactly(:activation, :satisfaction)
      end

      it 'determines status correctly' do
        plans = described_class.call(strategy)

        # Week 1 has published content (highest priority)
        expect(plans[0][:status]).to eq(:published)

        # Week 2 has approved content (scheduled)
        expect(plans[1][:status]).to eq(:scheduled)
      end

      it 'calculates dates correctly' do
        plans = described_class.call(strategy)

        # August 2025 starts on Friday, Aug 1st
        august_start = Date.new(2025, 8, 1)

        expect(plans[0][:start_date]).to eq(august_start)
        expect(plans[0][:end_date]).to eq(august_start + 6.days)

        expect(plans[1][:start_date]).to eq(august_start + 7.days)
        expect(plans[1][:end_date]).to eq(august_start + 13.days)
      end

      it 'preserves idea data' do
        plans = described_class.call(strategy)

        first_idea = plans[0][:ideas][0]
        expect(first_idea['id']).to eq("202508-brand-w1-i1-C")
        expect(first_idea['title']).to eq("Growth Content")
        expect(first_idea['pilar']).to eq("C")
        expect(first_idea['status']).to eq("draft")
      end

      context 'with invalid month' do
        let(:strategy) { create(:creas_strategy_plan, user: user, brand: brand, month: "invalid", weekly_plan: weekly_plan) }

        it 'falls back to current month' do
          plans = described_class.call(strategy)

          current_start = Date.current.beginning_of_month
          expect(plans[0][:start_date]).to eq(current_start)
        end
      end
    end
  end

  describe 'status hierarchy' do
    let(:strategy) { create(:creas_strategy_plan, user: user, brand: brand, weekly_plan: [ week_data ]) }

    context 'with published status' do
      let(:week_data) do
        {
          "week" => 1,
          "ideas" => [
            { "status" => "draft" },
            { "status" => "published" },
            { "status" => "in_production" }
          ]
        }
      end

      it 'returns published status' do
        plans = described_class.call(strategy)
        expect(plans[0][:status]).to eq(:published)
      end
    end

    context 'with no published but approved' do
      let(:week_data) do
        {
          "week" => 1,
          "ideas" => [
            { "status" => "draft" },
            { "status" => "approved" },
            { "status" => "in_production" }
          ]
        }
      end

      it 'returns scheduled status' do
        plans = described_class.call(strategy)
        expect(plans[0][:status]).to eq(:scheduled)
      end
    end

    context 'with empty ideas' do
      let(:week_data) { { "week" => 1, "ideas" => [] } }

      it 'returns needs_content status' do
        plans = described_class.call(strategy)
        expect(plans[0][:status]).to eq(:needs_content)
      end
    end
  end
end
