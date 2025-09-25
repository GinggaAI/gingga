require 'rails_helper'

RSpec.describe Planning::ContentRefinementService do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:strategy) { create(:creas_strategy_plan, brand: brand) }

  describe '#initialize' do
    it 'sets instance variables correctly' do
      service = described_class.new(strategy: strategy, target_week: 2, user: user)

      expect(service.send(:strategy)).to eq(strategy)
      expect(service.send(:target_week)).to eq(2)
      expect(service.send(:user)).to eq(user)
    end

    it 'handles nil target_week' do
      service = described_class.new(strategy: strategy, target_week: nil, user: user)

      expect(service.send(:target_week)).to be_nil
    end
  end

  describe '#call' do
    context 'when validation fails' do
      context 'with no strategy' do
        it 'returns validation error' do
          service = described_class.new(strategy: nil, target_week: 1, user: user)

          result = service.call

          expect(result.success?).to be false
          expect(result.error_message).to eq(I18n.t("planning.errors.no_strategy_to_refine"))
          expect(result.success_message).to be_nil
        end
      end

      context 'with invalid week number' do
        it 'returns validation error for week 0' do
          service = described_class.new(strategy: strategy, target_week: 0, user: user)

          result = service.call

          expect(result.success?).to be false
          expect(result.error_message).to eq(I18n.t("planning.errors.invalid_week_number"))
        end

        it 'returns validation error for week 5' do
          service = described_class.new(strategy: strategy, target_week: 5, user: user)

          result = service.call

          expect(result.success?).to be false
          expect(result.error_message).to eq(I18n.t("planning.errors.invalid_week_number"))
        end

        it 'returns validation error for negative week' do
          service = described_class.new(strategy: strategy, target_week: -1, user: user)

          result = service.call

          expect(result.success?).to be false
          expect(result.error_message).to eq(I18n.t("planning.errors.invalid_week_number"))
        end

        it 'returns validation error for non-integer week' do
          service = described_class.new(strategy: strategy, target_week: "week1", user: user)

          result = service.call

          expect(result.success?).to be false
          expect(result.error_message).to eq(I18n.t("planning.errors.invalid_week_number"))
        end
      end
    end

    context 'when validation passes' do
      let(:voxa_service) { double("Creas::VoxaContentService") }

      context 'when VoxaContentService succeeds' do
        context 'with specific target week' do
          it 'returns success result with week-specific message' do
            allow(Creas::VoxaContentService).to receive(:new).and_return(voxa_service)
            allow(voxa_service).to receive(:call).and_return(true)

            service = described_class.new(strategy: strategy, target_week: 2, user: user)
            result = service.call

            expect(result.success?).to be true
            expect(result.success_message).to eq(I18n.t("planning.messages.week_refinement_started", week: 2))
            expect(result.error_message).to be_nil
          end

          it 'calls VoxaContentService with correct parameters' do
            expect(Creas::VoxaContentService).to receive(:new).with(
              strategy_plan: strategy,
              target_week: 3
            ).and_return(voxa_service)
            expect(voxa_service).to receive(:call)

            service = described_class.new(strategy: strategy, target_week: 3, user: user)
            service.call
          end
        end

        context 'without specific target week (full refinement)' do
          it 'returns success result with general message' do
            allow(Creas::VoxaContentService).to receive(:new).and_return(voxa_service)
            allow(voxa_service).to receive(:call).and_return(true)

            service = described_class.new(strategy: strategy, target_week: nil, user: user)
            result = service.call

            expect(result.success?).to be true
            expect(result.success_message).to eq(I18n.t("planning.messages.content_refinement_started"))
            expect(result.error_message).to be_nil
          end

          it 'calls VoxaContentService with nil target_week' do
            expect(Creas::VoxaContentService).to receive(:new).with(
              strategy_plan: strategy,
              target_week: nil
            ).and_return(voxa_service)
            expect(voxa_service).to receive(:call)

            service = described_class.new(strategy: strategy, target_week: nil, user: user)
            service.call
          end
        end
      end

      context 'when VoxaContentService raises ServiceError' do
        let(:service_error) { Creas::VoxaContentService::ServiceError.new("API error", user_message: "User friendly message") }

        before do
          allow(Creas::VoxaContentService).to receive(:new).and_return(voxa_service)
          allow(voxa_service).to receive(:call).and_raise(service_error)
        end

        it 'returns error result with user message' do
          service = described_class.new(strategy: strategy, target_week: 1, user: user)
          result = service.call

          expect(result.success?).to be false
          expect(result.error_message).to eq("User friendly message")
          expect(result.success_message).to be_nil
        end
      end

      context 'when VoxaContentService raises unexpected error' do
        before do
          allow(Creas::VoxaContentService).to receive(:new).and_return(voxa_service)
          allow(voxa_service).to receive(:call).and_raise(StandardError.new("Unexpected error"))
        end

        it 'returns error result with generic message for specific week' do
          service = described_class.new(strategy: strategy, target_week: 2, user: user)
          result = service.call

          expect(result.success?).to be false
          expect(result.error_message).to eq(I18n.t("planning.messages.failed_to_refine_content", context: "week 2 "))
          expect(result.success_message).to be_nil
        end

        it 'returns error result with generic message for full refinement' do
          service = described_class.new(strategy: strategy, target_week: nil, user: user)
          result = service.call

          expect(result.success?).to be false
          expect(result.error_message).to eq(I18n.t("planning.messages.failed_to_refine_content", context: ""))
          expect(result.success_message).to be_nil
        end
      end
    end
  end

  describe '#valid? (private method coverage)' do
    context 'when strategy is present' do
      it 'returns true for nil target_week' do
        service = described_class.new(strategy: strategy, target_week: nil, user: user)

        expect(service.send(:valid?)).to be true
      end

      it 'returns true for valid week numbers' do
        (1..4).each do |week|
          service = described_class.new(strategy: strategy, target_week: week, user: user)
          expect(service.send(:valid?)).to be true
        end
      end

      it 'returns false for invalid week numbers' do
        [0, 5, -1, 10].each do |week|
          service = described_class.new(strategy: strategy, target_week: week, user: user)
          expect(service.send(:valid?)).to be false
        end
      end
    end

    context 'when strategy is nil' do
      it 'returns false regardless of target_week' do
        service = described_class.new(strategy: nil, target_week: 1, user: user)

        expect(service.send(:valid?)).to be false
      end
    end
  end

  describe '#valid_week_number? (private method coverage)' do
    it 'returns true for nil target_week' do
      service = described_class.new(strategy: strategy, target_week: nil, user: user)

      expect(service.send(:valid_week_number?)).to be true
    end

    it 'returns true for weeks 1-4' do
      (1..4).each do |week|
        service = described_class.new(strategy: strategy, target_week: week, user: user)
        expect(service.send(:valid_week_number?)).to be true
      end
    end

    it 'returns false for weeks outside 1-4' do
      [0, 5, -1, 10].each do |week|
        service = described_class.new(strategy: strategy, target_week: week, user: user)
        expect(service.send(:valid_week_number?)).to be false
      end
    end

    it 'returns false for non-integer values' do
      ["week1", 1.5, "2", nil].each do |week|
        next if week.nil? # nil is handled separately and returns true
        service = described_class.new(strategy: strategy, target_week: week, user: user)
        expect(service.send(:valid_week_number?)).to be false
      end
    end
  end

  describe 'Result struct' do
    it 'can be created with keyword arguments' do
      result = described_class::Result.new(
        success?: true,
        success_message: "Success!",
        error_message: nil
      )

      expect(result.success?).to be true
      expect(result.success_message).to eq("Success!")
      expect(result.error_message).to be_nil
    end

    it 'has default nil values' do
      result = described_class::Result.new

      expect(result.success?).to be_nil
      expect(result.success_message).to be_nil
      expect(result.error_message).to be_nil
    end
  end
end