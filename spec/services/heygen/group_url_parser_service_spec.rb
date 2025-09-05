require 'rails_helper'

RSpec.describe Heygen::GroupUrlParserService do
  describe '#call' do
    context 'with valid HeyGen group URL' do
      it 'extracts group_id successfully' do
        url = "https://app.heygen.com/avatars?groupId=658b8651cf7c4f36833da197fbbcafdd&tab=private"
        service = described_class.new(url: url)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:data][:group_id]).to eq("658b8651cf7c4f36833da197fbbcafdd")
        expect(result[:error]).to be_nil
      end

      it 'handles URL without tab parameter' do
        url = "https://app.heygen.com/avatars?groupId=658b8651cf7c4f36833da197fbbcafdd"
        service = described_class.new(url: url)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:data][:group_id]).to eq("658b8651cf7c4f36833da197fbbcafdd")
      end
    end

    context 'with invalid URL' do
      it 'returns error for empty URL' do
        service = described_class.new(url: "")
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("URL is required")
      end

      it 'returns error for nil URL' do
        service = described_class.new(url: nil)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("URL is required")
      end

      it 'returns error for invalid URL format' do
        service = described_class.new(url: "not-a-url")
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to include("Invalid")  # Could be "Invalid URL format" or "Invalid HeyGen URL"
      end

      it 'returns error for non-HeyGen URL' do
        url = "https://google.com/avatars?groupId=658b8651cf7c4f36833da197fbbcafdd"
        service = described_class.new(url: url)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Invalid HeyGen URL. Expected format: https://app.heygen.com/avatars?groupId=...")
      end

      it 'returns error for wrong HeyGen path' do
        url = "https://app.heygen.com/videos?groupId=658b8651cf7c4f36833da197fbbcafdd"
        service = described_class.new(url: url)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Invalid HeyGen URL. Expected format: https://app.heygen.com/avatars?groupId=...")
      end

      it 'returns error for HTTP instead of HTTPS' do
        url = "http://app.heygen.com/avatars?groupId=658b8651cf7c4f36833da197fbbcafdd"
        service = described_class.new(url: url)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Invalid HeyGen URL. Expected format: https://app.heygen.com/avatars?groupId=...")
      end
    end

    context 'with missing or invalid groupId' do
      it 'returns error when groupId is missing' do
        url = "https://app.heygen.com/avatars?tab=private"
        service = described_class.new(url: url)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("groupId parameter not found in URL")
      end

      it 'returns error when groupId is empty' do
        url = "https://app.heygen.com/avatars?groupId=&tab=private"
        service = described_class.new(url: url)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("groupId parameter not found in URL")
      end

      it 'returns error for invalid groupId format' do
        url = "https://app.heygen.com/avatars?groupId=invalid-format"
        service = described_class.new(url: url)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Invalid groupId format")
      end

      it 'returns error for short groupId' do
        url = "https://app.heygen.com/avatars?groupId=123abc"  # Only 6 chars, should be 20+
        service = described_class.new(url: url)
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Invalid groupId format")
      end
    end

    context 'edge cases' do
      it 'handles URL with extra whitespace' do
        url = "  https://app.heygen.com/avatars?groupId=658b8651cf7c4f36833da197fbbcafdd  "
        service = described_class.new(url: url)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:data][:group_id]).to eq("658b8651cf7c4f36833da197fbbcafdd")
      end

      it 'handles URL with multiple query parameters' do
        url = "https://app.heygen.com/avatars?sort=name&groupId=658b8651cf7c4f36833da197fbbcafdd&tab=private&limit=10"
        service = described_class.new(url: url)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:data][:group_id]).to eq("658b8651cf7c4f36833da197fbbcafdd")
      end
    end
  end
end
