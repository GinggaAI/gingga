require 'rails_helper'
require 'ostruct'

RSpec.describe Reels::InitializationService do
  let(:user) { create(:user) }
  let(:template) { "only_avatars" }
  let(:smart_planning_data) { nil }

  subject(:service) do
    described_class.new(
      user: user,
      template: template,
      smart_planning_data: smart_planning_data
    )
  end

  describe '#call' do
    context 'with valid template' do
      before do
        allow(ReelCreationService).to receive(:new).and_return(
          double(initialize_reel: { success: true, reel: build(:reel) })
        )
        allow(Reels::PresenterService).to receive(:new).and_return(
          double(call: OpenStruct.new(
            success?: true,
            data: { presenter: double, view_template: "reels/scene_based" }
          ))
        )
      end

      it 'returns successful result' do
        result = service.call

        expect(result.success?).to be true
        expect(result.data).to include(:reel, :presenter, :view_template)
      end
    end

    context 'with invalid template' do
      let(:template) { "invalid_template" }

      it 'returns failure result' do
        result = service.call

        expect(result.success?).to be false
        expect(result.error).to eq("Invalid template")
      end
    end

    context 'when reel creation fails' do
      before do
        allow(ReelCreationService).to receive(:new).and_return(
          double(initialize_reel: { success: false, error: "Reel creation failed" })
        )
      end

      it 'returns failure result with error message' do
        result = service.call

        expect(result.success?).to be false
        expect(result.error).to eq("Reel creation failed")
      end
    end

    context 'when presenter service fails' do
      before do
        allow(ReelCreationService).to receive(:new).and_return(
          double(initialize_reel: { success: true, reel: build(:reel) })
        )
        allow(Reels::PresenterService).to receive(:new).and_return(
          double(call: OpenStruct.new(
            success?: false,
            error: "Presenter setup failed"
          ))
        )
      end

      it 'returns failure result with presenter error' do
        result = service.call

        expect(result.success?).to be false
        expect(result.error).to eq("Presenter setup failed")
      end
    end

    context 'with smart planning data' do
      let(:smart_planning_data) { '{"title": "Test Reel"}' }

      before do
        allow(ReelCreationService).to receive(:new).and_return(
          double(initialize_reel: { success: true, reel: build(:reel) })
        )
        allow(Reels::SmartPlanningPreloadService).to receive(:new).and_return(
          double(call: OpenStruct.new(success?: true))
        )
        allow(Reels::PresenterService).to receive(:new).and_return(
          double(call: OpenStruct.new(
            success?: true,
            data: { presenter: double, view_template: "reels/scene_based" }
          ))
        )
      end

      it 'calls smart planning preload service' do
        expect(Reels::SmartPlanningPreloadService).to receive(:new)
        service.call
      end
    end

    context 'when smart planning preload fails' do
      let(:smart_planning_data) { '{"title": "Test Reel"}' }

      before do
        allow(ReelCreationService).to receive(:new).and_return(
          double(initialize_reel: { success: true, reel: build(:reel) })
        )
        allow(Reels::SmartPlanningPreloadService).to receive(:new).and_return(
          double(call: OpenStruct.new(success?: false, error: "Preload failed"))
        )
        allow(Reels::PresenterService).to receive(:new).and_return(
          double(call: OpenStruct.new(
            success?: true,
            data: { presenter: double, view_template: "reels/scene_based" }
          ))
        )
      end

      it 'logs warning but continues with initialization' do
        expect(Rails.logger).to receive(:warn).with(/Smart planning preload failed/)

        result = service.call

        expect(result.success?).to be true
      end
    end

    context 'when exception is raised' do
      before do
        allow(ReelCreationService).to receive(:new).and_raise(StandardError, "Unexpected error")
      end

      it 'handles exception and returns failure result' do
        expect(Rails.logger).to receive(:error).with(/Reel initialization failed/)
        expect(Rails.logger).to receive(:error)

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include("Failed to initialize reel: Unexpected error")
      end
    end

    context 'with all valid templates' do
      %w[only_avatars avatar_and_video narration_over_7_images one_to_three_videos].each do |template|
        context "with template #{template}" do
          let(:template) { template }

          before do
            allow(ReelCreationService).to receive(:new).and_return(
              double(initialize_reel: { success: true, reel: build(:reel) })
            )
            allow(Reels::PresenterService).to receive(:new).and_return(
              double(call: OpenStruct.new(
                success?: true,
                data: { presenter: double, view_template: "reels/scene_based" }
              ))
            )
          end

          it 'accepts the template as valid' do
            result = service.call
            expect(result.success?).to be true
          end
        end
      end
    end
  end
end
