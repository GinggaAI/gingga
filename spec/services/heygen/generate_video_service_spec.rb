require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Heygen::GenerateVideoService, type: :service do
  let(:user) { create(:user) }

  before do
    # Stub Heygen validation endpoint called during token creation
    stub_request(:get, "https://api.heygen.com/v2/avatars")
      .to_return(status: 200, body: '{"data": []}')
  end

  let!(:api_token) do
    # Skip the before_save callback to avoid API calls in tests
    ApiToken.skip_callback(:save, :before, :validate_token_with_provider)
    token = create(:api_token, :heygen, user: user, is_valid: true)
    ApiToken.set_callback(:save, :before, :validate_token_with_provider)
    token
  end
  let(:reel) { create(:reel, user: user) }

  before do
    create(:reel_scene, reel: reel, scene_number: 1, avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'Hello world')
    create(:reel_scene, reel: reel, scene_number: 2, avatar_id: 'avatar_2', voice_id: 'voice_2', script: 'Second scene')
    create(:reel_scene, reel: reel, scene_number: 3, avatar_id: 'avatar_3', voice_id: 'voice_3', script: 'Final scene')
  end

  subject { described_class.new(user, reel) }

  describe '#call' do
    context 'when reel is ready for generation' do
      let(:mock_response) do
        {
          'data' => {
            'video_id' => 'heygen_video_123'
          }
        }
      end

      before do
        allow(reel).to receive(:ready_for_generation?).and_return(true)
        mock_response_double = OpenStruct.new(
          success?: true,
          body: mock_response
        )

        allow(subject).to receive(:generate_video).and_return(mock_response_double)
      end

      it 'updates reel status to processing' do
        expect { subject.call }.to change { reel.reload.status }.to('processing')
      end

      it 'makes API call with correct payload' do
        expected_payload = {
          video_inputs: [
            {
              character: {
                type: "avatar",
                avatar_id: 'avatar_1',
                avatar_style: "normal"
              },
              voice: {
                type: "text",
                input_text: 'Hello world',
                voice_id: 'voice_1'
              },
              background: {
                type: "color",
                value: "#ffffff"
              }
            },
            {
              character: {
                type: "avatar",
                avatar_id: 'avatar_2',
                avatar_style: "normal"
              },
              voice: {
                type: "text",
                input_text: 'Second scene',
                voice_id: 'voice_2'
              },
              background: {
                type: "color",
                value: "#ffffff"
              }
            },
            {
              character: {
                type: "avatar",
                avatar_id: 'avatar_3',
                avatar_style: "normal"
              },
              voice: {
                type: "text",
                input_text: 'Final scene',
                voice_id: 'voice_3'
              },
              background: {
                type: "color",
                value: "#ffffff"
              }
            }
          ],
          dimension: {
            width: 720,
            height: 1280
          },
          aspect_ratio: "9:16",
          test: api_token.mode == 'test'
        }

        expect(subject).to receive(:generate_video).with(expected_payload).and_return(double(success?: true, body: mock_response))

        subject.call
      end

      it 'returns successful result with video data' do
        result = subject.call

        expect(result[:success]).to be true
        expect(result[:data][:video_id]).to eq('heygen_video_123')
        expect(result[:data][:status]).to eq('processing')
      end

      it 'updates reel with heygen video ID' do
        subject.call
        reel.reload

        expect(reel.heygen_video_id).to eq('heygen_video_123')
        expect(reel.status).to eq('processing')
      end

      context 'when API token is in test mode' do
        let!(:api_token) do
          # Skip the before_save callback to avoid API calls in tests
          ApiToken.skip_callback(:save, :before, :validate_token_with_provider)
          token = create(:api_token, :heygen, user: user, is_valid: true, mode: 'test')
          ApiToken.set_callback(:save, :before, :validate_token_with_provider)
          token
        end

        it 'includes test: true in payload' do
          expected_test_value = true

          expect(subject).to receive(:generate_video) do |payload|
            expect(payload[:test]).to eq(expected_test_value)
            double(success?: true, body: mock_response.to_json)
          end

          subject.call
        end
      end
    end

    context 'when reel is not ready for generation' do
      before do
        allow(reel).to receive(:ready_for_generation?).and_return(false)
      end

      it 'returns failure result' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Reel is not ready for generation')
      end
    end

    context 'when user has no valid API token' do
      let(:user_without_token) { create(:user) }
      subject { described_class.new(user_without_token, reel) }

      it 'returns failure result' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('No valid Heygen API token found')
      end
    end

    context 'when API call fails' do
      before do
        allow(reel).to receive(:ready_for_generation?).and_return(true)
        mock_response_double = OpenStruct.new(
          success?: false,
          message: 'API Error'
        )

        allow(subject).to receive(:generate_video).and_return(mock_response_double)
      end

      it 'returns failure result' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to generate video')
      end

      it 'updates reel status to failed' do
        expect { subject.call }.to change { reel.reload.status }.to('failed')
      end
    end

    context 'when an exception occurs' do
      before do
        allow(reel).to receive(:ready_for_generation?).and_return(true)
        allow(subject).to receive(:generate_video).and_raise(StandardError, 'Network error')
      end

      it 'returns failure result with error message' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Error generating video: Network error')
      end

      it 'updates reel status to failed' do
        expect { subject.call }.to change { reel.reload.status }.to('failed')
      end
    end
  end

  describe '#build_scene_input private method' do
    let(:service) { described_class.new(user, reel) }

    context 'when video_type is kling' do
      it 'builds character with type video' do
        scene = { avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'Test script', video_type: 'kling' }
        result = service.send(:build_scene_input, scene, 1)
        
        expect(result[:character][:type]).to eq('video')
        expect(result[:character][:video_content]).to eq('Test script')
        expect(result[:voice][:input_text]).to eq('Test script')
        expect(result[:voice][:voice_id]).to eq('voice_1')
      end
    end

    context 'when video_type is unknown' do
      it 'defaults to avatar type' do
        scene = { avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'Test script', video_type: 'unknown_type' }
        result = service.send(:build_scene_input, scene, 1)
        
        expect(result[:character][:type]).to eq('avatar')
        expect(result[:character][:avatar_id]).to eq('avatar_1')
        expect(result[:character][:avatar_style]).to eq('normal')
        expect(result[:voice][:input_text]).to eq('Test script')
        expect(result[:voice][:voice_id]).to eq('voice_1')
      end
    end

    context 'when video_type is nil' do
      it 'defaults to avatar type' do
        scene = { avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'Test script', video_type: nil }
        result = service.send(:build_scene_input, scene, 1)
        
        expect(result[:character][:type]).to eq('avatar')
        expect(result[:character][:avatar_id]).to eq('avatar_1')
        expect(result[:character][:avatar_style]).to eq('normal')
        expect(result[:voice][:input_text]).to eq('Test script')
        expect(result[:voice][:voice_id]).to eq('voice_1')
      end
    end

    context 'when video_type is avatar' do
      it 'builds character with avatar type' do
        scene = { avatar_id: 'avatar_1', voice_id: 'voice_1', script: 'Test script', video_type: 'avatar' }
        result = service.send(:build_scene_input, scene, 1)
        
        expect(result[:character][:type]).to eq('avatar')
        expect(result[:character][:avatar_id]).to eq('avatar_1')
        expect(result[:character][:avatar_style]).to eq('normal')
        expect(result[:voice][:input_text]).to eq('Test script')
        expect(result[:voice][:voice_id]).to eq('voice_1')
      end
    end
  end
end
