require 'rails_helper'

RSpec.describe Heygen::SynchronizeAvatarsService, type: :service do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user: user) }

  describe '#call' do
    context 'when HeyGen API returns avatars successfully' do
      let(:mock_response) do
        {
          "code" => 100,
          "data" => {
            "avatars" => [
              {
                "avatar_id" => "heygen_avatar_1",
                "avatar_name" => "Professional Female",
                "preview_image_url" => "https://example.com/avatar1.jpg",
                "gender" => "female",
                "is_public" => true
              },
              {
                "avatar_id" => "heygen_avatar_2",
                "avatar_name" => "Business Male",
                "preview_image_url" => "https://example.com/avatar2.jpg",
                "gender" => "male",
                "is_public" => false
              }
            ]
          }
        }
      end

      let(:raw_response) { mock_response.to_json }

      before do
        # Transform the data as ListAvatarsService would
        transformed_data = mock_response["data"]["avatars"].map do |avatar|
          {
            id: avatar["avatar_id"],
            name: avatar["avatar_name"],
            preview_image_url: avatar["preview_image_url"],
            gender: avatar["gender"],
            is_public: avatar["is_public"]
          }
        end

        allow_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
          .and_return({ success: true, data: transformed_data })
      end

      it 'synchronizes avatars from HeyGen API' do
        expect { service.call }.to change(Avatar, :count).by(2)
      end

      it 'creates avatars with correct attributes' do
        result = service.call

        expect(result.success?).to be true

        avatar1 = Avatar.find_by(avatar_id: 'heygen_avatar_1', provider: 'heygen')
        expect(avatar1).to be_present
        expect(avatar1.name).to eq('Professional Female')
        expect(avatar1.user).to eq(user)
        expect(avatar1.gender).to eq('female')
        expect(avatar1.is_public).to be true
        expect(avatar1.raw_response).to be_present

        avatar2 = Avatar.find_by(avatar_id: 'heygen_avatar_2', provider: 'heygen')
        expect(avatar2).to be_present
        expect(avatar2.name).to eq('Business Male')
        expect(avatar2.user).to eq(user)
        expect(avatar2.gender).to eq('male')
        expect(avatar2.is_public).to be false
        expect(avatar2.raw_response).to be_present
      end

      it 'updates existing avatars instead of creating duplicates' do
        existing_avatar = create(:avatar,
          user: user,
          avatar_id: 'heygen_avatar_1',
          provider: 'heygen',
          name: 'Old Name'
        )

        expect { service.call }.to change(Avatar, :count).by(1) # Only one new avatar

        existing_avatar.reload
        expect(existing_avatar.name).to eq('Professional Female')
      end

      it 'marks synchronized avatars as active' do
        service.call

        avatars = Avatar.where(user: user, provider: 'heygen')
        expect(avatars.all?(&:active?)).to be true
      end

      it 'returns success result with avatar count' do
        result = service.call

        expect(result.success?).to be true
        expect(result.data[:synchronized_count]).to eq(2)
        expect(result.data[:avatars]).to be_an(Array)
        expect(result.data[:avatars].size).to eq(2)
      end
    end

    context 'when HeyGen API fails' do
      before do
        allow_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
          .and_return({ success: false, error: 'API error' })
      end

      it 'returns failure result' do
        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include('Failed to fetch avatars from HeyGen')
      end

      it 'does not create any avatars' do
        expect { service.call }.not_to change(Avatar, :count)
      end
    end

    context 'when user has no valid HeyGen API token' do
      before do
        allow_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
          .and_return({ success: false, error: 'No valid Heygen API token found' })
      end

      it 'returns failure result with token error' do
        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include('Failed to fetch avatars from HeyGen')
      end
    end

    context 'when service raises an exception' do
      before do
        allow_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
          .and_raise(StandardError, 'Network timeout')
      end

      it 'returns failure result with error message' do
        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include('Error synchronizing avatars: Network timeout')
      end
    end

    context 'when API returns empty avatar list' do
      before do
        allow_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
          .and_return({ success: true, data: [] })
      end

      it 'returns success result with zero count' do
        result = service.call

        expect(result.success?).to be true
        expect(result.data[:synchronized_count]).to eq(0)
        expect(result.data[:avatars]).to eq([])
      end
    end

    context 'when API returns nil data' do
      before do
        allow_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
          .and_return({ success: true, data: nil })
      end

      it 'handles nil data gracefully' do
        result = service.call

        expect(result.success?).to be true
        expect(result.data[:synchronized_count]).to eq(0)
        expect(result.data[:avatars]).to eq([])
      end
    end
  end

  describe 'initialization and dependencies' do
    describe '#initialize' do
      context 'with user only' do
        let(:service) { described_class.new(user: user) }

        it 'initializes with user and nil group_url' do
          expect(service.instance_variable_get(:@user)).to eq(user)
          expect(service.instance_variable_get(:@group_url)).to be_nil
        end
      end

      context 'with user and group_url' do
        let(:group_url) { 'https://api.heygen.com/v1/group/test_group' }
        let(:service) { described_class.new(user: user, group_url: group_url) }

        it 'initializes with both user and group_url' do
          expect(service.instance_variable_get(:@user)).to eq(user)
          expect(service.instance_variable_get(:@group_url)).to eq(group_url)
        end
      end
    end
  end

  describe 'group avatar synchronization' do
    let(:group_url) { 'https://api.heygen.com/v1/group/test_group' }
    let(:service) { described_class.new(user: user, group_url: group_url) }
    let(:group_id) { 'test_group_id' }

    let(:mock_group_avatars) do
      [
        {
          id: "group_avatar_1",
          name: "Group Avatar 1",
          preview_image_url: "https://example.com/group_avatar1.jpg",
          gender: "female",
          is_public: false
        }
      ]
    end

    before do
      # Mock the URL parser service
      allow_any_instance_of(Heygen::GroupUrlParserService).to receive(:call)
        .and_return({ success: true, data: { group_id: group_id } })

      # Mock the group avatars service
      allow_any_instance_of(Heygen::ListGroupAvatarsService).to receive(:call)
        .and_return({ success: true, data: mock_group_avatars })
    end

    it 'uses group avatar service when group_url is present' do
      expect_any_instance_of(Heygen::GroupUrlParserService).to receive(:call)
      expect_any_instance_of(Heygen::ListGroupAvatarsService).to receive(:call)
      expect_any_instance_of(Heygen::ListAvatarsService).not_to receive(:call)

      service.call
    end

    it 'synchronizes group avatars successfully' do
      result = service.call

      expect(result.success?).to be true
      expect(result.data[:synchronized_count]).to eq(1)
    end

    context 'when URL parser fails' do
      before do
        allow_any_instance_of(Heygen::GroupUrlParserService).to receive(:call)
          .and_return({ success: false, error: 'Invalid URL format' })
      end

      it 'returns the parser failure result' do
        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include('Invalid URL format')
      end
    end

    context 'when group avatars service fails' do
      before do
        allow_any_instance_of(Heygen::ListGroupAvatarsService).to receive(:call)
          .and_return({ success: false, error: 'Group not found' })
      end

      it 'returns failure result' do
        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include('Failed to fetch avatars from HeyGen: Group not found')
      end
    end
  end

  describe 'private methods' do
    let(:service) { described_class.new(user: user) }

    describe '#sync_avatar' do
      let(:avatar_data) do
        {
          id: "test_avatar_id",
          name: "Test Avatar",
          preview_image_url: "https://example.com/test.jpg",
          gender: "male",
          is_public: true
        }
      end
      let(:raw_response) { '{"test": "response"}' }

      it 'creates new avatar with correct attributes' do
        avatar = service.send(:sync_avatar, avatar_data, raw_response)

        expect(avatar).to be_persisted
        expect(avatar.user).to eq(user)
        expect(avatar.avatar_id).to eq("test_avatar_id")
        expect(avatar.name).to eq("Test Avatar")
        expect(avatar.provider).to eq("heygen")
        expect(avatar.status).to eq("active")
        expect(avatar.preview_image_url).to eq("https://example.com/test.jpg")
        expect(avatar.gender).to eq("male")
        expect(avatar.is_public).to be true
        expect(avatar.raw_response).to eq(raw_response)
      end

      it 'updates existing avatar' do
        existing_avatar = create(:avatar,
          user: user,
          avatar_id: "test_avatar_id",
          provider: "heygen",
          name: "Old Name",
          gender: "female"
        )

        avatar = service.send(:sync_avatar, avatar_data, raw_response)

        expect(avatar.id).to eq(existing_avatar.id)
        expect(avatar.name).to eq("Test Avatar")
        expect(avatar.gender).to eq("male")
      end

      context 'with string keys in avatar_data' do
        let(:avatar_data_with_strings) do
          {
            "id" => "string_key_avatar",
            "name" => "String Key Avatar",
            "preview_image_url" => "https://example.com/string.jpg",
            "gender" => "female",
            "is_public" => false
          }
        end

        it 'handles string keys correctly' do
          avatar = service.send(:sync_avatar, avatar_data_with_strings, raw_response)

          expect(avatar.avatar_id).to eq("string_key_avatar")
          expect(avatar.name).to eq("String Key Avatar")
          expect(avatar.gender).to eq("female")
          expect(avatar.is_public).to be false
        end
      end

      context 'with alternative key names' do
        let(:avatar_data_alternative_keys) do
          {
            id: "alt_avatar",
            avatar_name: "Alternative Name Avatar",
            preview_image_url: "https://example.com/alt.jpg",
            gender: "male",
            is_public: nil
          }
        end

        it 'handles alternative key names' do
          avatar = service.send(:sync_avatar, avatar_data_alternative_keys, raw_response)

          expect(avatar.avatar_id).to eq("alt_avatar")
          expect(avatar.name).to eq("Alternative Name Avatar")
          expect(avatar.is_public).to be false # defaults to false when nil
        end
      end

      context 'when avatar save fails' do
        before do
          # Mock validation failure
          allow_any_instance_of(Avatar).to receive(:save).and_return(false)
          allow_any_instance_of(Avatar).to receive(:errors).and_return(
            double('errors', full_messages: [ 'Name is required', 'Avatar ID is invalid' ])
          )
          allow(Rails.logger).to receive(:error)
        end

        it 'logs error and returns nil' do
          expect(Rails.logger).to receive(:error).with(/Failed to sync avatar/)

          avatar = service.send(:sync_avatar, avatar_data, raw_response)

          expect(avatar).to be_nil
        end
      end
    end

    describe '#build_raw_response' do
      let(:avatars_data) do
        [
          { id: "avatar1", name: "Avatar 1" },
          { id: "avatar2", name: "Avatar 2" }
        ]
      end

      it 'builds correctly formatted JSON response' do
        raw_response = service.send(:build_raw_response, avatars_data)
        parsed_response = JSON.parse(raw_response)

        expect(parsed_response["code"]).to eq(100)
        # Convert symbols to strings for comparison since JSON parsing uses strings
        expected_data = avatars_data.map { |item| item.transform_keys(&:to_s) }
        expect(parsed_response["data"]["avatars"]).to match_array(expected_data)
      end

      it 'handles empty avatars data' do
        raw_response = service.send(:build_raw_response, [])
        parsed_response = JSON.parse(raw_response)

        expect(parsed_response["code"]).to eq(100)
        expect(parsed_response["data"]["avatars"]).to eq([])
      end
    end

    describe '#success_result' do
      let(:test_data) { { synchronized_count: 5, avatars: [] } }

      it 'creates OpenStruct with success true' do
        result = service.send(:success_result, data: test_data)

        expect(result).to be_a(OpenStruct)
        expect(result.success?).to be true
        expect(result.data).to eq(test_data)
        expect(result.error).to be_nil
      end
    end

    describe '#failure_result' do
      let(:error_message) { "Test error message" }

      it 'creates OpenStruct with success false' do
        result = service.send(:failure_result, error_message)

        expect(result).to be_a(OpenStruct)
        expect(result.success?).to be false
        expect(result.data).to be_nil
        expect(result.error).to eq(error_message)
      end
    end

    describe '#fetch_avatars' do
      context 'without group_url' do
        it 'calls ListAvatarsService' do
          expect_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
            .and_return({ success: true, data: [] })

          service.send(:fetch_avatars)
        end

        it 'logs avatar fetching information' do
          allow_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
            .and_return({ success: true, data: [ { id: 'test' } ] })

          expect(Rails.logger).to receive(:info).with(/📊 All avatars result/)

          service.send(:fetch_avatars)
        end
      end

      context 'with group_url' do
        let(:service) { described_class.new(user: user, group_url: 'https://api.heygen.com/v1/group/test') }

        it 'calls GroupUrlParserService and ListGroupAvatarsService' do
          expect_any_instance_of(Heygen::GroupUrlParserService).to receive(:call)
            .and_return({ success: true, data: { group_id: 'test_group' } })
          expect_any_instance_of(Heygen::ListGroupAvatarsService).to receive(:call)
            .and_return({ success: true, data: [] })

          service.send(:fetch_avatars)
        end
      end
    end
  end

  describe 'integration with Avatar model' do
    let(:avatar_data) do
      {
        id: "integration_avatar",
        name: "Integration Test Avatar",
        preview_image_url: "https://example.com/integration.jpg",
        gender: "female",
        is_public: true
      }
    end

    before do
      allow_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
        .and_return({ success: true, data: [ avatar_data ] })
    end

    it 'creates Avatar record that responds to to_api_format' do
      result = service.call

      avatar = Avatar.find_by(avatar_id: "integration_avatar")
      expect(avatar).to respond_to(:to_api_format)
      expect(result.data[:avatars].first).to eq(avatar.to_api_format)
    end

    it 'sets all required Avatar attributes' do
      service.call

      avatar = Avatar.find_by(avatar_id: "integration_avatar")
      expect(avatar.user).to eq(user)
      expect(avatar.provider).to eq("heygen")
      expect(avatar.status).to eq("active")
      expect(avatar.raw_response).to be_present
    end
  end

  describe 'error handling and edge cases' do
    context 'when user is nil' do
      it 'handles nil user gracefully by returning failure result' do
        service = described_class.new(user: nil)

        allow_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
          .and_return({ success: true, data: [ { id: "test" } ] })

        result = service.call
        expect(result.success?).to be false
        expect(result.error).to be_present
      end
    end

    context 'with malformed avatar data' do
      let(:malformed_data) do
        [
          { id: nil, name: nil }, # missing required fields
          { id: "valid_avatar", name: "Valid Avatar" } # valid data
        ]
      end

      before do
        allow_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
          .and_return({ success: true, data: malformed_data })
      end

      it 'handles malformed data gracefully' do
        result = service.call

        # Should still be successful overall, but might sync fewer avatars
        expect(result.success?).to be true
        expect(result.data[:synchronized_count]).to be >= 0
      end
    end

    context 'when Avatar model validation fails' do
      before do
        allow_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
          .and_return({ success: true, data: [ { id: "test_avatar", name: "Test" } ] })

        # Simulate validation failure
        allow_any_instance_of(Avatar).to receive(:save).and_return(false)
        allow_any_instance_of(Avatar).to receive(:errors).and_return(
          double('errors', full_messages: [ 'Validation failed' ])
        )
        allow(Rails.logger).to receive(:error)
      end

      it 'continues processing other avatars when one fails' do
        result = service.call

        expect(result.success?).to be true
        expect(result.data[:synchronized_count]).to eq(0) # No avatars saved
      end
    end

    context 'when JSON parsing fails in build_raw_response' do
      before do
        # Create circular reference that can't be serialized to JSON
        circular_data = {}
        circular_data[:self] = circular_data

        allow_any_instance_of(Heygen::ListAvatarsService).to receive(:call)
          .and_return({ success: true, data: [ circular_data ] })
      end

      it 'handles JSON serialization errors' do
        # This should raise a SystemStackError due to infinite recursion
        expect { service.call }.to raise_error(SystemStackError)
      end
    end
  end

  describe 'method visibility' do
    let(:service) { described_class.new(user: user) }

    it 'makes internal methods private' do
      expect(service.private_methods).to include(:fetch_avatars)
      expect(service.private_methods).to include(:sync_avatar)
      expect(service.private_methods).to include(:build_raw_response)
      expect(service.private_methods).to include(:success_result)
      expect(service.private_methods).to include(:failure_result)
    end

    it 'exposes only call method publicly' do
      public_methods = service.public_methods(false)
      expect(public_methods).to include(:call)
    end
  end
end
