require 'rails_helper'

RSpec.describe Reels::BaseCreationService do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:template) { 'only_avatars' }
  let(:params) { { title: 'Test Reel', description: 'Test description' } }

  subject(:service) do
    described_class.new(
      user: user,
      brand: brand,
      template: template,
      params: params
    )
  end

  describe '#initialize_reel' do
    context 'when reel initialization succeeds' do
      it 'creates and saves a reel with draft status' do
        result = service.initialize_reel

        expect(result[:success]).to be true
        expect(result[:reel]).to be_persisted
        expect(result[:reel].template).to eq('only_avatars')
        expect(result[:reel].status).to eq('draft')
        expect(result[:reel].user).to eq(user)
        expect(result[:error]).to be_nil
      end

      it 'calls setup_template_specific_fields' do
        expect(service).to receive(:setup_template_specific_fields)
        service.initialize_reel
      end
    end

    context 'when reel save fails' do
      before do
        allow_any_instance_of(Reel).to receive(:save).and_return(false)
        allow_any_instance_of(Reel).to receive(:errors).and_return(
          double(full_messages: [ 'Title is required' ])
        )
      end

      it 'returns failure result with error message' do
        result = service.initialize_reel

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to initialize reel')
        expect(result[:error]).to include('Title is required')
        expect(result[:reel]).to be_present
      end
    end
  end

  describe '#call' do
    context 'when reel creation succeeds' do
      let(:reel) { build(:reel, user: user, template: template, status: 'draft') }

      before do
        allow(user.reels).to receive(:build).and_return(reel)
        allow(reel).to receive(:save).and_return(true)
        allow(service).to receive(:trigger_video_generation)
      end

      it 'creates reel and triggers video generation' do
        result = service.call

        expect(result[:success]).to be true
        expect(result[:reel]).to eq(reel)
        expect(result[:error]).to be_nil
        expect(service).to have_received(:trigger_video_generation).with(reel)
      end

      it 'calls setup_template_specific_fields for new records' do
        allow(reel).to receive(:new_record?).and_return(true)
        expect(service).to receive(:setup_template_specific_fields).with(reel)

        service.call
      end

      it 'does not call setup_template_specific_fields for existing records' do
        allow(reel).to receive(:new_record?).and_return(false)
        expect(service).not_to receive(:setup_template_specific_fields)

        service.call
      end
    end

    context 'when reel save fails' do
      let(:reel) { build(:reel, user: user, template: template, status: 'draft') }

      before do
        allow(brand.reels).to receive(:build).and_return(reel)
        allow(reel).to receive(:save).and_return(false)
      end

      it 'returns failure result' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Validation failed')
        expect(result[:reel]).to eq(reel)
      end
    end
  end

  describe '#trigger_video_generation' do
    let(:reel) { create(:reel, user: user, template: 'only_avatars', status: 'draft') }

    context 'when video should be generated' do
      before do
        allow(service).to receive(:should_generate_video?).with(reel).and_return(true)
        allow(reel).to receive(:ready_for_generation?).and_return(true)
      end

      context 'when generation succeeds' do
        before do
          allow(Heygen::GenerateVideoService).to receive(:new).and_return(
            double(call: { success: true, video_id: 'test_123' })
          )
          allow(CheckVideoStatusJob).to receive(:set).and_return(
            double(perform_later: true)
          )
        end

        it 'generates video and schedules status check' do
          expect(Heygen::GenerateVideoService).to receive(:new).with(user, reel)
          expect(CheckVideoStatusJob).to receive(:set).with(wait: 30.seconds)

          service.send(:trigger_video_generation, reel)
        end
      end

      context 'when generation fails' do
        before do
          allow(Heygen::GenerateVideoService).to receive(:new).and_return(
            double(call: { success: false, error: 'API Error' })
          )
          allow(reel).to receive(:update!)
        end

        it 'logs error and updates reel status to failed' do
          expect(Rails.logger).to receive(:error).with(/Video generation failed/)
          expect(reel).to receive(:update!).with(status: 'failed')

          service.send(:trigger_video_generation, reel)
        end
      end

      context 'when exception occurs' do
        before do
          allow(Heygen::GenerateVideoService).to receive(:new).and_raise(StandardError, 'Network error')
          allow(reel).to receive(:update!)
        end

        it 'handles exception and updates reel status to failed' do
          expect(Rails.logger).to receive(:error).with(/Error triggering video generation/)
          expect(reel).to receive(:update!).with(status: 'failed')

          service.send(:trigger_video_generation, reel)
        end
      end
    end

    context 'when video should not be generated' do
      before do
        allow(service).to receive(:should_generate_video?).with(reel).and_return(false)
      end

      it 'does not attempt to generate video' do
        expect(Heygen::GenerateVideoService).not_to receive(:new)
        service.send(:trigger_video_generation, reel)
      end
    end

    context 'when reel is not ready for generation' do
      before do
        allow(service).to receive(:should_generate_video?).with(reel).and_return(true)
        allow(reel).to receive(:ready_for_generation?).and_return(false)
      end

      it 'does not attempt to generate video' do
        expect(Heygen::GenerateVideoService).not_to receive(:new)
        service.send(:trigger_video_generation, reel)
      end
    end
  end

  describe '#should_generate_video?' do
    context 'with templates that support video generation' do
      [ 'only_avatars', 'avatar_and_video' ].each do |template|
        it "returns true for #{template} template" do
          reel = build(:reel, template: template)
          expect(service.send(:should_generate_video?, reel)).to be true
        end
      end
    end

    context 'with templates that do not support video generation' do
      [ 'narration_over_7_images', 'one_to_three_videos', 'other_template' ].each do |template|
        it "returns false for #{template} template" do
          reel = build(:reel, template: template)
          expect(service.send(:should_generate_video?, reel)).to be false
        end
      end
    end
  end

  describe '#setup_template_specific_fields' do
    let(:reel) { build(:reel) }

    it 'can be called without error (base implementation)' do
      expect { service.send(:setup_template_specific_fields, reel) }.not_to raise_error
    end
  end

  describe '#reel_params' do
    it 'merges params with draft status' do
      expected_params = params.merge(status: 'draft')
      expect(service.send(:reel_params)).to eq(expected_params)
    end
  end

  describe 'result methods' do
    let(:reel) { build(:reel) }

    describe '#success_result' do
      it 'returns success hash with reel' do
        result = service.send(:success_result, reel)

        expect(result[:success]).to be true
        expect(result[:reel]).to eq(reel)
        expect(result[:error]).to be_nil
      end
    end

    describe '#failure_result' do
      it 'returns failure hash with error message' do
        result = service.send(:failure_result, 'Test error')

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Test error')
        expect(result[:reel]).to be_nil
      end

      it 'returns failure hash with error message and reel' do
        result = service.send(:failure_result, 'Test error', reel)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Test error')
        expect(result[:reel]).to eq(reel)
      end
    end
  end
end
