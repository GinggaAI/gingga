require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Heygen::CheckVideoStatusService, type: :service do
  let(:user) { create(:user) }

  before do
    # Stub Heygen validation endpoint called during token creation
    stub_request(:get, "https://api.heygen.com/v2/avatars")
      .to_return(status: 200, body: '{"data": []}')
  end

  let!(:api_token) do
    token = build(:api_token, user: user, provider: 'heygen', is_valid: true)
    token.save(validate: false)
    token
  end
  let(:reel) do
    reel = create(:reel, user: user, heygen_video_id: 'heygen_video_123', status: 'processing')
    # Create the required 3 scenes for validation
    create(:reel_scene, reel: reel, scene_number: 1)
    create(:reel_scene, reel: reel, scene_number: 2)
    create(:reel_scene, reel: reel, scene_number: 3)
    reel
  end

  subject { described_class.new(user, reel) }

  describe '#call' do
    context 'when video is completed' do
      let(:mock_response) do
        {
          'data' => {
            'status' => 'completed',
            'video_url' => 'https://example.com/video.mp4',
            'thumbnail_url' => 'https://example.com/thumbnail.jpg',
            'duration' => 30,
            'created_at' => '2024-01-01T00:00:00Z'
          }
        }
      end

      before do
        # Stub the video status check endpoint
        stub_request(:get, "https://api.heygen.com/v1/video_status.get")
          .with(query: { video_id: reel.heygen_video_id }, headers: {
            'X-API-KEY' => api_token.encrypted_token,
            'Content-Type' => 'application/json'
          })
          .to_return(status: 200, body: mock_response.to_json)
      end

      it 'makes API call with correct video ID' do
        # The WebMock stub above will verify the correct endpoint is called
        result = subject.call
        expect(result[:success]).to be true
      end

      it 'returns successful result with status data' do
        result = subject.call

        expect(result[:success]).to be true
        expect(result[:data][:status]).to eq('completed')
        expect(result[:data][:video_url]).to eq('https://example.com/video.mp4')
        expect(result[:data][:thumbnail_url]).to eq('https://example.com/thumbnail.jpg')
        expect(result[:data][:duration]).to eq(30)
      end

      it 'updates reel with video data' do
        subject.call
        reel.reload

        expect(reel.status).to eq('completed')
        expect(reel.video_url).to eq('https://example.com/video.mp4')
        expect(reel.thumbnail_url).to eq('https://example.com/thumbnail.jpg')
        expect(reel.duration).to eq(30)
      end
    end

    context 'when video is still processing' do
      let(:mock_response) do
        {
          'data' => {
            'status' => 'processing',
            'video_url' => nil,
            'thumbnail_url' => nil,
            'duration' => nil,
            'created_at' => '2024-01-01T00:00:00Z'
          }
        }
      end

      before do
        stub_request(:get, "https://api.heygen.com/v1/video_status.get")
          .with(query: { video_id: reel.heygen_video_id }, headers: {
            'X-API-KEY' => api_token.encrypted_token,
            'Content-Type' => 'application/json'
          })
          .to_return(status: 200, body: mock_response.to_json)
      end

      it 'updates reel status but not video data' do
        subject.call
        reel.reload

        expect(reel.status).to eq('processing')
        expect(reel.video_url).to be_nil
        expect(reel.thumbnail_url).to be_nil
        expect(reel.duration).to be_nil
      end
    end

    context 'when video has failed' do
      let(:mock_response) do
        {
          'data' => {
            'status' => 'failed',
            'video_url' => nil,
            'thumbnail_url' => nil,
            'duration' => nil,
            'created_at' => '2024-01-01T00:00:00Z'
          }
        }
      end

      before do
        stub_request(:get, "https://api.heygen.com/v1/video_status.get")
          .with(query: { video_id: reel.heygen_video_id }, headers: {
            'X-API-KEY' => api_token.encrypted_token,
            'Content-Type' => 'application/json'
          })
          .to_return(status: 200, body: mock_response.to_json)
      end

      it 'updates reel status to failed' do
        subject.call
        reel.reload

        expect(reel.status).to eq('failed')
      end
    end

    context 'when mapping different Heygen status values' do
      [ 'pending', 'processing' ].each do |heygen_status|
        it "maps '#{heygen_status}' to 'processing'" do
          mock_response = { 'data' => { 'status' => heygen_status } }

          stub_request(:get, "https://api.heygen.com/v1/video_status.get")
            .with(query: { video_id: reel.heygen_video_id }, headers: {
              'X-API-KEY' => api_token.encrypted_token,
              'Content-Type' => 'application/json'
            })
            .to_return(status: 200, body: mock_response.to_json)

          subject.call
          expect(reel.reload.status).to eq('processing')
        end
      end

      [ 'completed', 'success' ].each do |heygen_status|
        it "maps '#{heygen_status}' to 'completed'" do
          mock_response = { 'data' => { 'status' => heygen_status } }

          stub_request(:get, "https://api.heygen.com/v1/video_status.get")
            .with(query: { video_id: reel.heygen_video_id }, headers: {
              'X-API-KEY' => api_token.encrypted_token,
              'Content-Type' => 'application/json'
            })
            .to_return(status: 200, body: mock_response.to_json)

          subject.call
          expect(reel.reload.status).to eq('completed')
        end
      end

      [ 'failed', 'error' ].each do |heygen_status|
        it "maps '#{heygen_status}' to 'failed'" do
          mock_response = { 'data' => { 'status' => heygen_status } }

          stub_request(:get, "https://api.heygen.com/v1/video_status.get")
            .with(query: { video_id: reel.heygen_video_id }, headers: {
              'X-API-KEY' => api_token.encrypted_token,
              'Content-Type' => 'application/json'
            })
            .to_return(status: 200, body: mock_response.to_json)

          subject.call
          expect(reel.reload.status).to eq('failed')
        end
      end
    end

    context 'when reel has no heygen_video_id' do
      let(:reel_without_video_id) do
        reel = create(:reel, user: user, heygen_video_id: nil)
        # Create the required 3 scenes for validation
        create(:reel_scene, reel: reel, scene_number: 1)
        create(:reel_scene, reel: reel, scene_number: 2)
        create(:reel_scene, reel: reel, scene_number: 3)
        reel
      end
      subject { described_class.new(user, reel_without_video_id) }

      it 'returns failure result' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Reel has no Heygen video ID')
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
        stub_request(:get, "https://api.heygen.com/v1/video_status.get")
          .with(query: { video_id: reel.heygen_video_id }, headers: {
            'X-API-KEY' => api_token.encrypted_token,
            'Content-Type' => 'application/json'
          })
          .to_return(status: 500, body: '{"error": "Server error"}')
      end

      it 'returns failure result' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to check video status')
      end
    end

    context 'when an exception occurs' do
      before do
        stub_request(:get, "https://api.heygen.com/v1/video_status.get")
          .with(query: { video_id: reel.heygen_video_id }, headers: {
            'X-API-KEY' => api_token.encrypted_token,
            'Content-Type' => 'application/json'
          })
          .to_raise(StandardError, 'Network error')
      end

      it 'returns failure result with error message' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to include('Error checking video status:')
      end
    end
  end
end
