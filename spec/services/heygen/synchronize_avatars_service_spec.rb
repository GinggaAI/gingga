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
  end
end
