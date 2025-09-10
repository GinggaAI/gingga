require 'rails_helper'

RSpec.describe ApiResponse, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      expect(ApiResponse.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    subject { build(:api_response) }

    it 'validates presence of provider' do
      subject.provider = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:provider]).to include("can't be blank")
    end

    it 'validates provider is in allowed list' do
      subject.provider = 'invalid_provider'
      expect(subject).not_to be_valid
      expect(subject.errors[:provider]).to include('is not included in the list')
    end

    it 'validates presence of endpoint' do
      subject.endpoint = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:endpoint]).to include("can't be blank")
    end

    it 'allows valid providers' do
      %w[openai heygen kling].each do |provider|
        subject.provider = provider
        expect(subject).to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:successful_response) { create(:api_response, :successful, user: user) }
    let!(:failed_response) { create(:api_response, :failed, user: user) }
    let!(:heygen_response) { create(:api_response, :heygen, user: user) }
    let!(:openai_response) { create(:api_response, :openai, user: user) }

    it 'filters by success status' do
      expect(ApiResponse.successful).to include(successful_response)
      expect(ApiResponse.successful).not_to include(failed_response)
    end

    it 'filters by failure status' do
      expect(ApiResponse.failed).to include(failed_response)
      expect(ApiResponse.failed).not_to include(successful_response)
    end

    it 'filters by provider' do
      expect(ApiResponse.by_provider('heygen')).to include(heygen_response)
      expect(ApiResponse.by_provider('heygen')).not_to include(openai_response)
    end

    it 'orders by recent first' do
      older_response = create(:api_response, user: user, created_at: 1.day.ago)
      recent_responses = ApiResponse.recent.limit(2)

      expect(recent_responses.first.created_at).to be > older_response.created_at
    end
  end

  describe '.log_api_call' do
    let(:user) { create(:user) }
    let(:provider) { 'heygen' }
    let(:endpoint) { '/v2/avatars' }
    let(:request_data) { { query: {}, headers: { "X-API-KEY" => "secret" } } }
    let(:response_data) { { code: 100, data: { avatars: [] } } }

    it 'creates an API response record' do
      expect {
        ApiResponse.log_api_call(
          provider: provider,
          endpoint: endpoint,
          user: user,
          request_data: request_data,
          response_data: response_data,
          status_code: 200,
          response_time_ms: 150,
          success: true
        )
      }.to change(ApiResponse, :count).by(1)
    end

    it 'stores request and response data as JSON' do
      api_response = ApiResponse.log_api_call(
        provider: provider,
        endpoint: endpoint,
        user: user,
        request_data: request_data,
        response_data: response_data,
        status_code: 200,
        response_time_ms: 150,
        success: true
      )

      expect(api_response.request_data).to eq(request_data.to_json)
      expect(api_response.response_data).to eq(response_data.to_json)
    end

    it 'handles nil request and response data' do
      expect {
        ApiResponse.log_api_call(
          provider: provider,
          endpoint: endpoint,
          user: user,
          request_data: nil,
          response_data: nil,
          status_code: 404,
          response_time_ms: 100,
          success: false,
          error_message: 'Not found'
        )
      }.to change(ApiResponse, :count).by(1)
    end

    it 'handles logging failures gracefully' do
      allow(ApiResponse).to receive(:create!).and_raise(StandardError, 'Database error')
      expect(Rails.logger).to receive(:error).with('Failed to log API response: Database error')

      expect {
        ApiResponse.log_api_call(
          provider: provider,
          endpoint: endpoint,
          user: user
        )
      }.not_to raise_error
    end
  end

  describe '#parsed_request_data' do
    it 'parses valid JSON request data' do
      request_data = { query: { limit: 10 }, headers: { "Content-Type" => "application/json" } }
      api_response = create(:api_response, request_data: request_data.to_json)

      expect(api_response.parsed_request_data).to eq(request_data.with_indifferent_access)
    end

    it 'returns empty hash for invalid JSON' do
      api_response = create(:api_response, request_data: 'invalid json')

      expect(api_response.parsed_request_data).to eq({})
    end

    it 'returns empty hash for nil request data' do
      api_response = create(:api_response, request_data: nil)

      expect(api_response.parsed_request_data).to eq({})
    end
  end

  describe '#parsed_response_data' do
    it 'parses valid JSON response data' do
      response_data = { code: 100, data: { avatars: [] } }
      api_response = create(:api_response, response_data: response_data.to_json)

      expect(api_response.parsed_response_data).to eq(response_data.with_indifferent_access)
    end

    it 'returns empty hash for invalid JSON' do
      api_response = create(:api_response, response_data: 'invalid json')

      expect(api_response.parsed_response_data).to eq({})
    end

    it 'returns empty hash for nil response data' do
      api_response = create(:api_response, response_data: nil)

      expect(api_response.parsed_response_data).to eq({})
    end
  end

  describe 'factory traits' do
    it 'creates heygen responses' do
      response = create(:api_response, :heygen)
      expect(response.provider).to eq('heygen')
      expect(response.endpoint).to eq('/v2/avatars')
    end

    it 'creates openai responses' do
      response = create(:api_response, :openai)
      expect(response.provider).to eq('openai')
      expect(response.endpoint).to eq('/v1/chat/completions')
    end

    it 'creates failed responses' do
      response = create(:api_response, :failed)
      expect(response.success).to be false
      expect(response.status_code).to eq(401)
      expect(response.error_message).to eq('Unauthorized')
    end

    it 'creates responses with avatar data' do
      response = create(:api_response, :with_avatar_data)
      parsed_data = response.parsed_response_data

      expect(parsed_data['code']).to eq(100)
      expect(parsed_data['data']['avatars']).to be_an(Array)
      expect(parsed_data['data']['avatars'].first['avatar_id']).to eq('avatar_123')
    end
  end

  describe 'integration with HeyGen services' do
    let(:user) { create(:user) }

    it 'logs API responses using log_api_call method' do
      # Test the direct logging mechanism rather than full integration
      # since the full service integration requires complex mocking

      expect {
        ApiResponse.log_api_call(
          provider: 'heygen',
          endpoint: '/v2/avatars',
          user: user,
          request_data: { headers: { "X-API-KEY" => "[REDACTED]" } },
          response_data: { code: 100, data: { avatars: [] } },
          status_code: 200,
          response_time_ms: 150,
          success: true
        )
      }.to change(ApiResponse, :count).by(1)

      api_response = ApiResponse.last
      expect(api_response.provider).to eq('heygen')
      expect(api_response.endpoint).to eq('/v2/avatars')
      expect(api_response.user).to eq(user)
      expect(api_response.success).to be true
      expect(api_response.status_code).to eq(200)
      expect(api_response.response_time_ms).to eq(150)
    end
  end
end
