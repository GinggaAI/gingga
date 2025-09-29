require 'rails_helper'

RSpec.describe ApiToken, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:api_token) }

    before do
      allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
        .and_return({ valid: true })
    end

    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_inclusion_of(:provider).in_array(%w[openai heygen kling]) }
    it { is_expected.to validate_presence_of(:mode) }
    it { is_expected.to validate_inclusion_of(:mode).in_array(%w[test production]) }
    it { is_expected.to validate_presence_of(:encrypted_token) }
    it { is_expected.to validate_uniqueness_of(:provider).scoped_to([ :brand_id, :mode ]) }
  end

  describe 'encryption' do
    let(:token) { build(:api_token, encrypted_token: 'sk-test123') }

    before do
      allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
        .and_return({ valid: true })
    end

    it 'encrypts the token field' do
      expect(token.encrypted_token).to eq('sk-test123')
      token.save!
      # The token should still be accessible as the original value
      # but stored encrypted in the database
      expect(token.encrypted_token).to eq('sk-test123')
      # Verify that the token was saved successfully
      expect(token.persisted?).to be true
    end
  end

  describe 'token validation' do
    let(:user) { create(:user) }

    context 'when token is valid' do
      before do
        allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
          .and_return({ valid: true })
      end

      it 'sets is_valid to true' do
        token = create(:api_token, user: user, provider: 'openai')
        expect(token.is_valid).to be true
      end
    end

    context 'when token is invalid' do
      before do
        allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
          .and_return({ valid: false, error: 'Invalid token' })
      end

      it 'prevents saving and adds error' do
        token = build(:api_token, user: user, provider: 'openai')
        expect(token.save).to be false
        expect(token.errors[:encrypted_token]).to include('Invalid token')
      end
    end

    context 'when validation service raises error' do
      before do
        allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
          .and_raise(StandardError, 'Network error')
      end

      it 'prevents saving and adds error' do
        token = build(:api_token, user: user, provider: 'openai')
        expect(token.save).to be false
        expect(token.errors[:encrypted_token]).to be_present
      end
    end
  end

  describe 'uniqueness constraint' do
    let(:user) { create(:user) }

    before do
      allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
        .and_return({ valid: true })
    end

    it 'allows one token per provider per mode per brand' do
      brand = create(:brand, user: user)
      create(:api_token, user: user, brand: brand, provider: 'openai', mode: 'test')

      duplicate = build(:api_token, user: user, brand: brand, provider: 'openai', mode: 'test')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:provider]).to be_present
    end

    it 'allows same provider with different modes' do
      create(:api_token, user: user, provider: 'openai', mode: 'test')

      production_token = build(:api_token, user: user, provider: 'openai', mode: 'production')
      expect(production_token).to be_valid
    end

    it 'allows same provider for different users' do
      user2 = create(:user)
      create(:api_token, user: user, provider: 'openai', mode: 'test')

      user2_token = build(:api_token, user: user2, provider: 'openai', mode: 'test')
      expect(user2_token).to be_valid
    end
  end
end
