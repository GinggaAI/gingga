require 'rails_helper'
require Rails.root.join('app/services/gingga_openai/client_for_user')

RSpec.describe GinggaOpenAI::ClientForUser do
  describe '.access_token_for' do
    let(:user) { create(:user) }

    before do
      # Mock the API token validator to avoid real API calls
      allow_any_instance_of(ApiTokenValidatorService).to receive(:call).and_return({ valid: true })
    end

    context 'when user has active OpenAI token' do
      let!(:openai_token) { create(:api_token, :openai, user: user, mode: 'production') }

      it 'returns the encrypted token' do
        expect(described_class.access_token_for(user)).to eq(openai_token.encrypted_token)
      end
    end

    context 'when user has no OpenAI token' do
      it 'returns ENV fallback' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("env_key")
        expect(described_class.access_token_for(user)).to eq("env_key")
      end
    end

    context 'when user is nil' do
      it 'returns ENV fallback' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("env_key")
        expect(described_class.access_token_for(nil)).to eq("env_key")
      end
    end
  end
end
