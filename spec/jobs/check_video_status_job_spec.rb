require 'rails_helper'

RSpec.describe CheckVideoStatusJob, type: :job do
  let(:user) { create(:user) }
  let(:reel) { create(:reel, user: user, status: 'processing', heygen_video_id: 'test_video_123') }

  describe '#perform' do
    context 'when reel exists and is processing' do
      let(:check_service) { instance_double(Heygen::CheckVideoStatusService) }

      before do
        allow(Heygen::CheckVideoStatusService).to receive(:new).and_return(check_service)
      end

      context 'when service call is successful' do
        context 'when video is still processing' do
          it 'schedules another check in 30 seconds' do
            allow(check_service).to receive(:call).and_return({
              success: true,
              data: { status: 'processing' }
            })

            expect(CheckVideoStatusJob).to receive(:set).with(wait: 30.seconds).and_return(CheckVideoStatusJob)
            expect(CheckVideoStatusJob).to receive(:perform_later).with(reel.id)

            CheckVideoStatusJob.perform_now(reel.id)
          end
        end

        context 'when video is completed' do
          it 'does not schedule another check' do
            allow(check_service).to receive(:call).and_return({
              success: true,
              data: { status: 'completed' }
            })

            expect(CheckVideoStatusJob).not_to receive(:set)

            CheckVideoStatusJob.perform_now(reel.id)
          end
        end

        context 'when video has failed' do
          it 'does not schedule another check' do
            allow(check_service).to receive(:call).and_return({
              success: true,
              data: { status: 'failed' }
            })

            expect(CheckVideoStatusJob).not_to receive(:set)

            CheckVideoStatusJob.perform_now(reel.id)
          end
        end
      end

      context 'when service call fails' do
        it 'schedules retry in 60 seconds' do
          allow(check_service).to receive(:call).and_return({
            success: false,
            error: 'API Error'
          })

          expect(CheckVideoStatusJob).to receive(:set).with(wait: 60.seconds).and_return(CheckVideoStatusJob)
          expect(CheckVideoStatusJob).to receive(:perform_later).with(reel.id)

          CheckVideoStatusJob.perform_now(reel.id)
        end
      end
    end

    context 'when reel does not exist' do
      it 'returns early without processing' do
        expect(Heygen::CheckVideoStatusService).not_to receive(:new)

        CheckVideoStatusJob.perform_now(999999)
      end
    end

    context 'when reel is not processing' do
      let(:completed_reel) { create(:reel, user: user, status: 'completed') }

      it 'returns early without processing' do
        expect(Heygen::CheckVideoStatusService).not_to receive(:new)

        CheckVideoStatusJob.perform_now(completed_reel.id)
      end
    end

    context 'when reel has no heygen_video_id' do
      let(:reel_without_video_id) { create(:reel, user: user, status: 'processing', heygen_video_id: nil) }

      it 'returns early without processing' do
        expect(Heygen::CheckVideoStatusService).not_to receive(:new)

        CheckVideoStatusJob.perform_now(reel_without_video_id.id)
      end
    end

    context 'when exception occurs' do
      it 'schedules retry in 60 seconds' do
        allow(Reel).to receive(:find_by).and_raise(StandardError, 'Database error')

        expect(CheckVideoStatusJob).to receive(:set).with(wait: 60.seconds).and_return(CheckVideoStatusJob)
        expect(CheckVideoStatusJob).to receive(:perform_later).with(reel.id)
        expect(Rails.logger).to receive(:error).with(/Exception checking video status/)

        CheckVideoStatusJob.perform_now(reel.id)
      end
    end
  end
end
