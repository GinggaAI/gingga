require 'rails_helper'

RSpec.describe Planning::ContentDetailsService do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:valid_content_data) do
    {
      title: "Content Title",
      description: "Content description",
      category: "educational"
    }.to_json
  end

  before do
    allow(Planning::BrandResolver).to receive(:call).with(user).and_return(brand)
  end

  describe '#call' do
    context 'with valid content data' do
      it 'returns success with rendered HTML' do
        service = described_class.new(content_data: valid_content_data, user: user)

        result = service.call

        expect(result.success?).to be true
        expect(result.html).to be_present
        expect(result.error_message).to be_nil
      end

      it 'builds presenter with user brand' do
        service = described_class.new(content_data: valid_content_data, user: user)

        expect(PlanningPresenter).to receive(:new)
          .with({}, brand: brand, current_plan: nil)
          .and_call_original

        service.call
      end

      it 'renders the content_detail partial' do
        service = described_class.new(content_data: valid_content_data, user: user)

        expect(ApplicationController.renderer).to receive(:render)
          .with(
            partial: "plannings/content_detail",
            locals: hash_including(:content_piece, :presenter),
            formats: [ :html ]
          ).and_return("<div>rendered content</div>")

        result = service.call
        expect(result.html).to eq("<div>rendered content</div>")
      end
    end

    context 'with missing content data' do
      it 'returns validation error for nil content data' do
        service = described_class.new(content_data: nil, user: user)

        result = service.call

        expect(result.success?).to be false
        expect(result.error_message).to eq("Content data is required")
        expect(result.status_code).to eq(:bad_request)
      end

      it 'returns validation error for empty content data' do
        service = described_class.new(content_data: "", user: user)

        result = service.call

        expect(result.success?).to be false
        expect(result.error_message).to eq("Content data is required")
        expect(result.status_code).to eq(:bad_request)
      end
    end

    context 'with invalid JSON content data' do
      it 'returns JSON parse error' do
        service = described_class.new(content_data: "invalid json {", user: user)

        result = service.call

        expect(result.success?).to be false
        expect(result.error_message).to eq("Invalid content data format")
        expect(result.status_code).to eq(:bad_request)
      end

      it 'logs JSON parsing error' do
        service = described_class.new(content_data: "invalid json {", user: user)

        expect(Rails.logger).to receive(:error)
          .with(/ContentDetailsService: Failed to parse content data/)
        expect(Rails.logger).to receive(:error)
          .with(/Raw content_data: invalid json \{/)

        service.call
      end
    end

    context 'when rendering fails' do
      it 'handles rendering errors gracefully' do
        service = described_class.new(content_data: valid_content_data, user: user)

        allow(ApplicationController.renderer).to receive(:render)
          .and_raise(StandardError.new("Template not found"))

        result = service.call

        expect(result.success?).to be false
        expect(result.error_message).to eq("Failed to render content details")
        expect(result.status_code).to eq(:internal_server_error)
      end

      it 'logs rendering errors with backtrace' do
        service = described_class.new(content_data: valid_content_data, user: user)
        error = StandardError.new("Template not found")

        allow(ApplicationController.renderer).to receive(:render).and_raise(error)
        expect(Rails.logger).to receive(:error)
          .with(/ContentDetailsService: Error rendering content details/)
        expect(Rails.logger).to receive(:error)
          .with(/Backtrace:/)

        service.call
      end
    end

    context 'with brand resolver' do
      it 'calls brand resolver with user' do
        service = described_class.new(content_data: valid_content_data, user: user)

        expect(Planning::BrandResolver).to receive(:call).with(user).and_return(brand)

        service.call
      end

      it 'caches brand resolver result' do
        service = described_class.new(content_data: valid_content_data, user: user)

        expect(Planning::BrandResolver).to receive(:call).once.with(user).and_return(brand)

        # Call twice to test caching
        service.send(:user_brand)
        service.send(:user_brand)
      end
    end
  end

  describe 'Result struct' do
    it 'creates result with success' do
      result = Planning::ContentDetailsService::Result.new(
        success?: true,
        html: "<div>content</div>"
      )

      expect(result.success?).to be true
      expect(result.html).to eq("<div>content</div>")
      expect(result.error_message).to be_nil
      expect(result.status_code).to be_nil
    end

    it 'creates result with error' do
      result = Planning::ContentDetailsService::Result.new(
        success?: false,
        error_message: "Error occurred",
        status_code: :bad_request
      )

      expect(result.success?).to be false
      expect(result.error_message).to eq("Error occurred")
      expect(result.status_code).to eq(:bad_request)
      expect(result.html).to be_nil
    end
  end
end
