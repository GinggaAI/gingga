require 'rails_helper'

RSpec.describe CreasStrategyPlan, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:brand) }
    it { should have_many(:creas_posts).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:month) }
    it { should validate_presence_of(:objective_of_the_month) }
    it { should validate_presence_of(:frequency_per_week) }
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
end
