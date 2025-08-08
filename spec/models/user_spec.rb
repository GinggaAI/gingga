require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:api_tokens).dependent(:destroy) }
  end

  describe '#active_token_for' do
    let(:user) { create(:user) }

    before do
      allow_any_instance_of(ApiTokenValidatorService).to receive(:call)
        .and_return({ valid: true })
    end

    context 'when production token exists' do
      let!(:production_token) { create(:api_token, user: user, provider: 'openai', mode: 'production') }
      let!(:test_token) { create(:api_token, user: user, provider: 'openai', mode: 'test') }

      it 'returns production token by default' do
        token = user.active_token_for('openai')
        expect(token).to eq(production_token)
      end

      it 'returns production token when explicitly requested' do
        token = user.active_token_for('openai', 'production')
        expect(token).to eq(production_token)
      end

      it 'returns test token when test mode requested' do
        token = user.active_token_for('openai', 'test')
        expect(token).to eq(test_token)
      end
    end

    context 'when only test token exists' do
      let!(:test_token) { create(:api_token, user: user, provider: 'openai', mode: 'test') }

      it 'falls back to test token when production requested' do
        token = user.active_token_for('openai', 'production')
        expect(token).to eq(test_token)
      end

      it 'returns test token when test mode requested' do
        token = user.active_token_for('openai', 'test')
        expect(token).to eq(test_token)
      end
    end

    context 'when no valid tokens exist' do
      it 'returns nil' do
        # Create token that will be marked as invalid
        token = create(:api_token, user: user, provider: 'openai')
        # Update the token to invalid after creation (bypassing validations)
        token.update_column(:is_valid, false)

        result = user.active_token_for('openai')
        expect(result).to be_nil
      end
    end

    context 'when no tokens exist for provider' do
      let!(:heygen_token) { create(:api_token, user: user, provider: 'heygen') }

      it 'returns nil for different provider' do
        token = user.active_token_for('openai')
        expect(token).to be_nil
      end
    end
  end
end
