require 'rails_helper'

RSpec.describe CreasStrategyPlan, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:brand) }
    it { should have_many(:creas_posts).dependent(:destroy) }
    it { should have_many(:creas_content_items).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:month) }

    context 'when status is completed' do
      subject { build(:creas_strategy_plan, status: :completed) }
      it { should validate_presence_of(:objective_of_the_month) }
      it { should validate_presence_of(:frequency_per_week) }
    end

    context 'when status is not completed' do
      subject { build(:creas_strategy_plan, status: :pending) }
      it { should_not validate_presence_of(:objective_of_the_month) }
      it { should_not validate_presence_of(:frequency_per_week) }
    end
  end

  describe 'status enum' do
    it 'has the correct status values' do
      expect(CreasStrategyPlan.statuses).to eq({
        'pending' => 'pending',
        'processing' => 'processing',
        'completed' => 'completed',
        'failed' => 'failed'
      })
    end

    it 'defaults to pending status' do
      plan = build(:creas_strategy_plan)
      expect(plan.status).to eq('pending')
      expect(plan.pending?).to be true
    end

    it 'can be set to different statuses' do
      plan = build(:creas_strategy_plan)

      plan.processing!
      expect(plan.processing?).to be true

      plan.completed!
      expect(plan.completed?).to be true

      plan.failed!
      expect(plan.failed?).to be true
    end
  end

  describe 'selected_templates validation' do
    let(:strategy_plan) { build(:creas_strategy_plan) }

    it 'is valid with allowed templates' do
      strategy_plan.selected_templates = [ 'only_avatars', 'avatar_and_video' ]
      expect(strategy_plan).to be_valid
    end

    it 'is invalid with empty array when completed' do
      strategy_plan.selected_templates = []
      strategy_plan.status = 'completed'
      expect(strategy_plan).not_to be_valid
      expect(strategy_plan.errors[:selected_templates]).to include("can't be blank")
    end

    it 'is invalid with disallowed templates' do
      strategy_plan.selected_templates = [ 'invalid_template' ]
      expect(strategy_plan).not_to be_valid
      expect(strategy_plan.errors[:selected_templates]).to include('contains invalid templates: invalid_template')
    end

    it 'is invalid when not an array' do
      strategy_plan.selected_templates = 'not_an_array'
      expect(strategy_plan).not_to be_valid
      expect(strategy_plan.errors[:selected_templates]).to include('must be an array')
    end

    it 'allows nil when pending' do
      strategy_plan.selected_templates = nil
      strategy_plan.status = 'pending'
      expect(strategy_plan).to be_valid
    end

    it 'is invalid with empty array when provided' do
      strategy_plan.selected_templates = []
      expect(strategy_plan).not_to be_valid
      expect(strategy_plan.errors[:selected_templates]).to include('cannot be empty when provided')
    end
  end

  describe 'scopes' do
    let!(:older_plan) { create(:creas_strategy_plan, created_at: 1.day.ago) }
    let!(:newer_plan) { create(:creas_strategy_plan, created_at: 1.hour.ago) }

    describe '.recent' do
      it 'orders plans by created_at descending' do
        expect(CreasStrategyPlan.recent).to eq([ newer_plan, older_plan ])
      end
    end
  end

  describe 'JSONB defaults' do
    let(:strategy_plan) { create(:creas_strategy_plan) }

    it 'has default empty arrays for monthly_themes' do
      expect(strategy_plan.monthly_themes).to be_an(Array)
    end

    it 'has default empty hashes for resources_override' do
      expect(strategy_plan.resources_override).to be_a(Hash)
    end

    it 'has default empty hashes for content_distribution' do
      expect(strategy_plan.content_distribution).to be_a(Hash)
    end

    it 'has default empty arrays for weekly_plan' do
      expect(strategy_plan.weekly_plan).to be_an(Array)
    end

    it 'has default empty hashes for remix_duet_plan' do
      expect(strategy_plan.remix_duet_plan).to be_a(Hash)
    end

    it 'has default empty hashes for publish_windows_local' do
      expect(strategy_plan.publish_windows_local).to be_a(Hash)
    end

    it 'has default empty hashes for brand_snapshot' do
      expect(strategy_plan.brand_snapshot).to be_a(Hash)
    end

    it 'has default empty hashes for raw_payload' do
      expect(strategy_plan.raw_payload).to be_a(Hash)
    end

    it 'has default empty hashes for meta' do
      expect(strategy_plan.meta).to be_a(Hash)
    end
  end

  describe 'instance methods' do
    let(:strategy_plan) { create(:creas_strategy_plan, month: "2025-08") }

    describe '#content_stats' do
      let!(:item1) { create(:creas_content_item, creas_strategy_plan: strategy_plan, status: "in_production", template: "only_avatars", video_source: "none") }
      let!(:item2) { create(:creas_content_item, creas_strategy_plan: strategy_plan, status: "ready_for_review", template: "only_avatars", video_source: "none") }
      let!(:item3) { create(:creas_content_item, creas_strategy_plan: strategy_plan, status: "in_production", template: "remix", video_source: "external") }

      it 'returns grouped stats by status, template, and video_source' do
        stats = strategy_plan.content_stats

        expect(stats[[ "in_production", "only_avatars", "none" ]]).to eq(1)
        expect(stats[[ "ready_for_review", "only_avatars", "none" ]]).to eq(1)
        expect(stats[[ "in_production", "remix", "external" ]]).to eq(1)
      end
    end

    describe '#current_week_items' do
      context 'when current date is within the strategy month' do
        let(:strategy_plan) { create(:creas_strategy_plan, month: Date.current.strftime("%Y-%m")) }
        let!(:week1_item) { create(:creas_content_item, creas_strategy_plan: strategy_plan, week: 1) }
        let!(:week2_item) { create(:creas_content_item, creas_strategy_plan: strategy_plan, week: 2) }

        it 'returns items for the current week' do
          current_week = ((Date.current - Date.current.beginning_of_month).to_i / 7) + 1
          expected_items = strategy_plan.creas_content_items.by_week(current_week)

          result = strategy_plan.current_week_items
          expect(result.to_a).to eq(expected_items.to_a)
        end
      end

      context 'when current date is outside the strategy month' do
        let(:strategy_plan) { create(:creas_strategy_plan, month: "2024-01") }

        it 'returns empty relation' do
          result = strategy_plan.current_week_items
          expect(result).to be_empty
        end
      end

      context 'when month is invalid' do
        let(:strategy_plan) { create(:creas_strategy_plan, month: "invalid-month") }

        it 'returns empty relation' do
          result = strategy_plan.current_week_items
          expect(result).to be_empty
        end

        it 'handles Date::Error gracefully' do
          # This ensures the Date::Error rescue clause is covered
          expect { strategy_plan.current_week_items }.not_to raise_error
        end
      end

      context 'when month is empty string' do
        let(:strategy_plan) do
          plan = create(:creas_strategy_plan)
          plan.update_column(:month, '')
          plan.reload
        end

        it 'returns empty relation' do
          result = strategy_plan.current_week_items
          expect(result).to be_empty
        end
      end

      context 'when current date is after month end' do
        before do
          allow(Date).to receive(:current).and_return(Date.parse("2025-09-01"))
        end

        let(:strategy_plan) { create(:creas_strategy_plan, month: "2025-08") }

        it 'returns empty relation' do
          result = strategy_plan.current_week_items
          expect(result).to be_empty
        end
      end

      context 'when current date is before month start' do
        before do
          allow(Date).to receive(:current).and_return(Date.parse("2025-07-31"))
        end

        let(:strategy_plan) { create(:creas_strategy_plan, month: "2025-08") }

        it 'returns empty relation' do
          result = strategy_plan.current_week_items
          expect(result).to be_empty
        end
      end

      context 'edge cases for week calculation' do
        before do
          allow(Date).to receive(:current).and_return(Date.parse("2025-08-15"))
        end

        let(:strategy_plan) { create(:creas_strategy_plan, month: "2025-08") }
        let!(:week3_item) { create(:creas_content_item, creas_strategy_plan: strategy_plan, week: 3) }
        let!(:week1_item) { create(:creas_content_item, creas_strategy_plan: strategy_plan, week: 1) }

        it 'correctly calculates current week for middle of month' do
          # Aug 15, 2025 should be in week 3 (days 15-21 of month)
          result = strategy_plan.current_week_items
          expect(result).to include(week3_item)
          expect(result).not_to include(week1_item)
        end
      end
    end
  end
end
