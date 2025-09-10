require 'rails_helper'

RSpec.describe Heygen::ListGroupAvatarsService do
  let(:user) { create(:user) }
  let(:group_id) { "658b8651cf7c4f36833da197fbbcafdd" }
  let!(:api_token) do
    # Skip the before_save callback to avoid API calls in tests
    ApiToken.skip_callback(:save, :before, :validate_token_with_provider)
    token = create(:api_token, :heygen, user: user, is_valid: true)
    ApiToken.set_callback(:save, :before, :validate_token_with_provider)
    token
  end

  describe '#call' do
    context 'with valid API token and group ID' do
      let(:mock_response_body) do
        {
          "code" => 100,
          "data" => {
            "avatar_list" => [
              {
                "avatar_id" => "test_avatar_1",
                "avatar_name" => "Test Avatar 1",
                "preview_image_url" => "https://example.com/avatar1.jpg",
                "gender" => "male",
                "is_public" => false
              },
              {
                "avatar_id" => "test_avatar_2",
                "avatar_name" => "Test Avatar 2",
                "preview_image_url" => "https://example.com/avatar2.jpg",
                "gender" => "female",
                "is_public" => true
              }
            ]
          }
        }
      end

      let(:mock_response) do
        OpenStruct.new(
          success?: true,
          body: mock_response_body
        )
      end

      before do
        # Mock the service instance to simulate successful authentication and API setup
        allow_any_instance_of(described_class).to receive(:api_token_present?).and_return(true)
        allow_any_instance_of(described_class).to receive(:get).and_return(mock_response)
        allow_any_instance_of(described_class).to receive(:parse_json).and_return(mock_response_body)

        # Set up @api_token instance variable for cache_key_for method
        allow(api_token).to receive(:mode).and_return('production')
      end

      it 'fetches avatars from specific group successfully' do
        service = described_class.new(user: user, group_id: group_id)

        # Set up the @api_token instance variable properly
        service.instance_variable_set(:@api_token, api_token)

        result = service.call

        expect(result[:success]).to be true
        expect(result[:data]).to be_an(Array)
        expect(result[:data].size).to eq(2)

        first_avatar = result[:data].first
        expect(first_avatar[:id]).to eq("test_avatar_1")
        expect(first_avatar[:name]).to eq("Test Avatar 1")
        expect(first_avatar[:preview_image_url]).to eq("https://example.com/avatar1.jpg")
        expect(first_avatar[:gender]).to eq("male")
        expect(first_avatar[:is_public]).to be false
      end

      it 'calls the correct API endpoint' do
        service = described_class.new(user: user, group_id: group_id)
        expected_endpoint = "/v2/avatar_group/#{group_id}/avatars"

        service.instance_variable_set(:@api_token, api_token)
        allow(service).to receive(:api_token_present?).and_return(true)
        allow(service).to receive(:parse_json).and_return(mock_response_body)
        expect(service).to receive(:get).with(expected_endpoint).and_return(mock_response)
        service.call
      end

      it 'implements caching functionality' do
        service = described_class.new(user: user, group_id: group_id)
        service.instance_variable_set(:@api_token, api_token)
        allow(service).to receive(:api_token_present?).and_return(true)

        # Test that the service has the cache_key method (private method)
        expect(service.private_methods).to include(:cache_key)

        # Test that cache_key returns expected format
        cache_key = service.send(:cache_key)
        expected_pattern = /\Aheygen_group_avatars_#{group_id}_#{user.id}_production\z/
        expect(cache_key).to match(expected_pattern)
      end
    end

    context 'with invalid parameters' do
      before do
        # Mock successful token validation for parameter validation tests
        allow_any_instance_of(described_class).to receive(:api_token_present?).and_return(true)
      end

      it 'returns error when group_id is blank' do
        service = described_class.new(user: user, group_id: "")
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Group ID is required")
      end

      it 'returns error when group_id is nil' do
        service = described_class.new(user: user, group_id: nil)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Group ID is required")
      end
    end

    context 'with no API token' do
      it 'returns error when no API token present' do
        user_without_token = create(:user)
        service = described_class.new(user: user_without_token, group_id: group_id)

        # Don't mock api_token_present? - let it return false naturally
        # since user_without_token has no API token
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("No valid Heygen API token found")
      end
    end

    context 'when API call fails' do
      let(:failed_response) do
        OpenStruct.new(success?: false, message: "Group not found")
      end

      before do
        allow_any_instance_of(described_class).to receive(:api_token_present?).and_return(true)
        allow_any_instance_of(described_class).to receive(:get).and_return(failed_response)
      end

      it 'returns error when API call fails' do
        service = described_class.new(user: user, group_id: group_id)

        service.instance_variable_set(:@api_token, api_token)

        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Failed to fetch group avatars: Group not found")
      end
    end

    context 'when API returns empty data' do
      let(:empty_response_body) do
        {
          "code" => 100,
          "data" => {}
        }
      end

      let(:empty_response) do
        OpenStruct.new(
          success?: true,
          body: empty_response_body
        )
      end

      before do
        allow_any_instance_of(described_class).to receive(:api_token_present?).and_return(true)
        allow_any_instance_of(described_class).to receive(:get).and_return(empty_response)
        allow_any_instance_of(described_class).to receive(:parse_json).and_return(empty_response_body)
      end

      it 'returns empty array when no avatars found' do
        service = described_class.new(user: user, group_id: group_id)

        service.instance_variable_set(:@api_token, api_token)

        result = service.call

        expect(result[:success]).to be true
        expect(result[:data]).to eq([])
      end
    end

    context 'when exception occurs' do
      before do
        allow_any_instance_of(described_class).to receive(:api_token_present?).and_return(true)
        allow_any_instance_of(described_class).to receive(:get).and_raise(StandardError.new("Network error"))
      end

      it 'returns error when exception occurs' do
        service = described_class.new(user: user, group_id: group_id)

        service.instance_variable_set(:@api_token, api_token)

        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Error fetching group avatars: Network error")
      end
    end
  end
end
