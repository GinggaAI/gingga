require 'rails_helper'
require 'ostruct'

RSpec.describe Heygen::ListMyAvatarsService, type: :service do
  let(:user) { create(:user) }
  let!(:api_token) do
    # Skip the before_save callback to avoid API calls in tests
    ApiToken.skip_callback(:save, :before, :validate_token_with_provider)
    token = create(:api_token, :heygen, user: user, is_valid: true)
    ApiToken.set_callback(:save, :before, :validate_token_with_provider)
    token
  end

  subject { described_class.new(user) }

  describe '#call' do
    context 'when user has valid API token' do
      let(:mock_groups_response) do
        {
          'avatar_group_list' => [
            {
              'id' => 'custom_group_1',
              'name' => 'My Custom Group 1',
              'group_type' => 'CUSTOM'
            },
            {
              'id' => 'public_group_1',
              'name' => 'Public Group 1',
              'group_type' => 'PUBLIC_PREMIUM'
            },
            {
              'id' => 'custom_group_2',
              'name' => 'My Custom Group 2',
              'group_type' => 'USER_CREATED'
            }
          ]
        }
      end

      let(:mock_avatars_group_1) do
        {
          'avatar_list' => [
            {
              'id' => 'avatar_1',
              'name' => 'Custom Avatar 1',
              'image_url' => 'https://example.com/avatar1.jpg'
            },
            {
              'id' => 'avatar_2',
              'name' => 'Custom Avatar 2',
              'image_url' => 'https://example.com/avatar2.jpg'
            }
          ]
        }
      end

      let(:mock_avatars_group_2) do
        {
          'avatar_list' => [
            {
              'id' => 'avatar_3',
              'name' => 'Custom Avatar 3',
              'image_url' => 'https://example.com/avatar3.jpg'
            }
          ]
        }
      end

      before do
        # Mock the groups response
        groups_response = OpenStruct.new(success?: true, body: mock_groups_response.to_json)
        allow(subject).to receive(:fetch_avatar_groups).and_return(groups_response)
        allow(subject).to receive(:parse_json).with(groups_response).and_return(mock_groups_response)

        # Mock the avatar responses for each custom group
        avatars_response_1 = OpenStruct.new(success?: true, body: mock_avatars_group_1.to_json)
        avatars_response_2 = OpenStruct.new(success?: true, body: mock_avatars_group_2.to_json)

        allow(subject).to receive(:get).with('/v2/avatar_group/custom_group_1/avatars').and_return(avatars_response_1)
        allow(subject).to receive(:get).with('/v2/avatar_group/custom_group_2/avatars').and_return(avatars_response_2)

        allow(subject).to receive(:parse_json).with(avatars_response_1).and_return(mock_avatars_group_1)
        allow(subject).to receive(:parse_json).with(avatars_response_2).and_return(mock_avatars_group_2)
      end

      it 'fetches custom avatars successfully' do
        result = subject.call

        expect(result[:success]).to be true
        expect(result[:data]).to be_an(Array)
        expect(result[:data].length).to eq(3)

        first_avatar = result[:data].first
        expect(first_avatar[:id]).to eq('avatar_1')
        expect(first_avatar[:name]).to eq('Custom Avatar 1')
        expect(first_avatar[:preview_image_url]).to eq('https://example.com/avatar1.jpg')
        expect(first_avatar[:group_id]).to eq('custom_group_1')
        expect(first_avatar[:group_type]).to eq('CUSTOM')
        expect(first_avatar[:source]).to eq('custom')
      end

      it 'filters out public groups' do
        result = subject.call

        # Should only include avatars from custom groups
        group_ids = result[:data].map { |avatar| avatar[:group_id] }.uniq
        expect(group_ids).to contain_exactly('custom_group_1', 'custom_group_2')
        expect(group_ids).not_to include('public_group_1')
      end

      it 'caches the result' do
        cache_key = "heygen_custom_avatars_#{user.id}_#{api_token.mode}"

        expect(Rails.cache).to receive(:read).with(cache_key).and_return(nil)
        expect(Rails.cache).to receive(:write).with(cache_key, anything, expires_in: 6.hours)

        subject.call
      end

      it 'returns cached result if available' do
        cached_avatars = [
          {
            id: 'cached_avatar_1',
            name: 'Cached Avatar 1',
            preview_image_url: 'https://example.com/cached.jpg',
            group_id: 'cached_group',
            group_type: 'CUSTOM',
            source: 'custom'
          }
        ]
        cache_key = "heygen_custom_avatars_#{user.id}_#{api_token.mode}"

        allow(Rails.cache).to receive(:read).with(cache_key).and_return(cached_avatars)
        expect(subject).not_to receive(:fetch_avatar_groups)

        result = subject.call
        expect(result[:success]).to be true
        expect(result[:data]).to eq(cached_avatars)
      end
    end

    context 'when user has no valid API token' do
      let(:user_without_token) { create(:user) }
      subject { described_class.new(user_without_token) }

      it 'returns failure result' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('No valid Heygen API token found')
      end
    end

    context 'when avatar groups fetch fails' do
      before do
        groups_response = OpenStruct.new(success?: false, message: 'API Error')
        allow(subject).to receive(:fetch_avatar_groups).and_return(groups_response)
      end

      it 'returns failure result' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Failed to fetch avatar groups: API Error')
      end
    end

    context 'when avatar fetch for specific group fails' do
      let(:mock_groups_response) do
        {
          'avatar_group_list' => [
            {
              'id' => 'custom_group_1',
              'name' => 'My Custom Group 1',
              'group_type' => 'CUSTOM'
            }
          ]
        }
      end

      before do
        # Mock successful groups response
        groups_response = OpenStruct.new(success?: true, body: mock_groups_response.to_json)
        allow(subject).to receive(:fetch_avatar_groups).and_return(groups_response)
        allow(subject).to receive(:parse_json).with(groups_response).and_return(mock_groups_response)

        # Mock failed avatar response for the group
        failed_response = OpenStruct.new(success?: false, message: 'Group not found')
        allow(subject).to receive(:get).with('/v2/avatar_group/custom_group_1/avatars').and_return(failed_response)
      end

      it 'skips failed groups and returns empty array' do
        result = subject.call

        expect(result[:success]).to be true
        expect(result[:data]).to eq([])
      end
    end

    context 'when groups response has no avatar_group_list' do
      before do
        groups_response = OpenStruct.new(success?: true, body: {}.to_json)
        allow(subject).to receive(:fetch_avatar_groups).and_return(groups_response)
        allow(subject).to receive(:parse_json).with(groups_response).and_return({})
      end

      it 'returns empty array' do
        result = subject.call

        expect(result[:success]).to be true
        expect(result[:data]).to eq([])
      end
    end

    context 'when group avatars response has no avatar_list' do
      let(:mock_groups_response) do
        {
          'avatar_group_list' => [
            {
              'id' => 'custom_group_1',
              'name' => 'My Custom Group 1',
              'group_type' => 'CUSTOM'
            }
          ]
        }
      end

      before do
        # Mock successful groups response
        groups_response = OpenStruct.new(success?: true, body: mock_groups_response.to_json)
        allow(subject).to receive(:fetch_avatar_groups).and_return(groups_response)
        allow(subject).to receive(:parse_json).with(groups_response).and_return(mock_groups_response)

        # Mock avatar response with no avatar_list
        avatars_response = OpenStruct.new(success?: true, body: {}.to_json)
        allow(subject).to receive(:get).with('/v2/avatar_group/custom_group_1/avatars').and_return(avatars_response)
        allow(subject).to receive(:parse_json).with(avatars_response).and_return({})
      end

      it 'returns empty array for that group' do
        result = subject.call

        expect(result[:success]).to be true
        expect(result[:data]).to eq([])
      end
    end

    context 'when an exception occurs' do
      before do
        allow(subject).to receive(:fetch_avatar_groups).and_raise(StandardError, 'Network error')
      end

      it 'returns failure result with error message' do
        result = subject.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Error fetching custom avatars: Network error')
      end
    end
  end

  describe 'private methods' do
    describe '#fetch_avatar_groups' do
      it 'calls the correct endpoint' do
        expect(subject).to receive(:get).with('/v2/avatar_group.list')
        subject.send(:fetch_avatar_groups)
      end
    end

    describe '#filter_custom_groups' do
      let(:response) { OpenStruct.new(body: mock_data.to_json) }
      let(:mock_data) do
        {
          'avatar_group_list' => [
            { 'id' => '1', 'group_type' => 'CUSTOM' },
            { 'id' => '2', 'group_type' => 'PUBLIC_PREMIUM' },
            { 'id' => '3', 'group_type' => 'PUBLIC_FREE' },
            { 'id' => '4', 'group_type' => 'USER_CREATED' }
          ]
        }
      end

      before do
        allow(subject).to receive(:parse_json).with(response).and_return(mock_data)
      end

      it 'filters out groups starting with PUBLIC_' do
        result = subject.send(:filter_custom_groups, response)

        expect(result.length).to eq(2)
        expect(result.map { |g| g['id'] }).to contain_exactly('1', '4')
        expect(result.map { |g| g['group_type'] }).to contain_exactly('CUSTOM', 'USER_CREATED')
      end
    end

    describe '#fetch_avatars_from_groups' do
      let(:groups) do
        [
          { 'id' => 'group_1', 'group_type' => 'CUSTOM' },
          { 'id' => 'group_2', 'group_type' => 'USER_CREATED' }
        ]
      end

      let(:mock_avatars_1) do
        {
          'avatar_list' => [
            {
              'id' => 'avatar_1',
              'name' => 'Avatar 1',
              'image_url' => 'https://example.com/avatar1.jpg'
            }
          ]
        }
      end

      let(:mock_avatars_2) do
        {
          'avatar_list' => [
            {
              'id' => 'avatar_2',
              'name' => 'Avatar 2',
              'image_url' => 'https://example.com/avatar2.jpg'
            }
          ]
        }
      end

      before do
        response_1 = OpenStruct.new(success?: true, body: mock_avatars_1.to_json)
        response_2 = OpenStruct.new(success?: true, body: mock_avatars_2.to_json)

        allow(subject).to receive(:get).with('/v2/avatar_group/group_1/avatars').and_return(response_1)
        allow(subject).to receive(:get).with('/v2/avatar_group/group_2/avatars').and_return(response_2)
        allow(subject).to receive(:parse_json).with(response_1).and_return(mock_avatars_1)
        allow(subject).to receive(:parse_json).with(response_2).and_return(mock_avatars_2)
      end

      it 'fetches and formats avatars from all groups' do
        result = subject.send(:fetch_avatars_from_groups, groups)

        expect(result.length).to eq(2)

        avatar_1 = result.first
        expect(avatar_1[:id]).to eq('avatar_1')
        expect(avatar_1[:name]).to eq('Avatar 1')
        expect(avatar_1[:preview_image_url]).to eq('https://example.com/avatar1.jpg')
        expect(avatar_1[:group_id]).to eq('group_1')
        expect(avatar_1[:group_type]).to eq('CUSTOM')
        expect(avatar_1[:source]).to eq('custom')
      end
    end

    describe '#cache_key' do
      it 'generates correct cache key' do
        cache_key = subject.send(:cache_key)
        expect(cache_key).to eq("heygen_custom_avatars_#{user.id}_#{api_token.mode}")
      end
    end
  end
end
