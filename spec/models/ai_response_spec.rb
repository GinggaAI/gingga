require 'rails_helper'

RSpec.describe AiResponse, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:service_name) }
    it { is_expected.to validate_presence_of(:ai_model) }
    it { is_expected.to validate_presence_of(:raw_response) }
  end

  describe 'scopes' do
    describe '.recent' do
      let!(:older_response) { create(:ai_response, user: user, created_at: 2.days.ago) }
      let!(:newer_response) { create(:ai_response, user: user, created_at: 1.day.ago) }

      it 'orders by created_at desc' do
        expect(AiResponse.recent.limit(2)).to eq([ newer_response, older_response ])
      end
    end

    describe '.by_service' do
      it 'filters by service name' do
        noctua_response = create(:ai_response, service_name: "noctua", user: user)
        voxa_response = create(:ai_response, service_name: "voxa", user: user)

        expect(AiResponse.by_service("noctua")).to include(noctua_response)
        expect(AiResponse.by_service("noctua")).not_to include(voxa_response)
        expect(AiResponse.by_service("voxa")).to include(voxa_response)
        expect(AiResponse.by_service("voxa")).not_to include(noctua_response)
      end
    end

    describe '.by_model' do
      it 'filters by AI model' do
        gpt4_response = create(:ai_response, ai_model: "gpt-4o", user: user)
        gpt35_response = create(:ai_response, ai_model: "gpt-3.5-turbo", user: user)

        expect(AiResponse.by_model("gpt-4o")).to include(gpt4_response)
        expect(AiResponse.by_model("gpt-4o")).not_to include(gpt35_response)
        expect(AiResponse.by_model("gpt-3.5-turbo")).to include(gpt35_response)
        expect(AiResponse.by_model("gpt-3.5-turbo")).not_to include(gpt4_response)
      end
    end

    describe '.by_version' do
      it 'filters by prompt version' do
        v1_response = create(:ai_response, prompt_version: "v1", user: user)
        v2_response = create(:ai_response, prompt_version: "v2", user: user)

        expect(AiResponse.by_version("v1")).to include(v1_response)
        expect(AiResponse.by_version("v1")).not_to include(v2_response)
        expect(AiResponse.by_version("v2")).to include(v2_response)
        expect(AiResponse.by_version("v2")).not_to include(v1_response)
      end
    end
  end

  describe '#parsed_response' do
    context 'with valid JSON string' do
      let(:response_data) { { "test" => "value" } }
      let(:ai_response) { create(:ai_response, raw_response: response_data.to_json, user: user) }

      it 'parses JSON correctly' do
        expect(ai_response.parsed_response).to eq(response_data)
      end
    end

    context 'with hash raw_response' do
      let(:response_data) { { "test" => "value" } }
      let(:ai_response) { create(:ai_response, raw_response: response_data, user: user) }

      it 'returns hash directly' do
        expect(ai_response.parsed_response).to eq(response_data)
      end
    end

    context 'with invalid JSON' do
      let(:ai_response) { create(:ai_response, raw_response: "invalid json{", user: user) }

      it 'returns nil for invalid JSON' do
        expect(ai_response.parsed_response).to be_nil
      end
    end
  end

  describe '#response_summary' do
    context 'with noctua service' do
      context 'with valid weekly_plan' do
        let(:response_data) do
          {
            "frequency_per_week" => 3,
            "weekly_plan" => [
              { "ideas" => [ {}, {}, {} ] },
              { "ideas" => [ {}, {} ] },
              { "ideas" => [ {}, {}, {} ] },
              { "ideas" => [ {}, {} ] }
            ]
          }
        end
        let(:ai_response) { create(:ai_response, service_name: "noctua", raw_response: response_data, user: user) }

        it 'returns frequency and weekly distribution summary' do
          expect(ai_response.response_summary).to eq("3/week target, actual: 3-2-3-2 (total: 10)")
        end
      end

      context 'without weekly_plan' do
        let(:response_data) { { "frequency_per_week" => 3 } }
        let(:ai_response) { create(:ai_response, service_name: "noctua", raw_response: response_data, user: user) }

        it 'returns no weekly_plan message' do
          expect(ai_response.response_summary).to eq("No weekly_plan found")
        end
      end
    end

    context 'with voxa service' do
      let(:response_data) { { "items" => [ {}, {}, {} ] } }
      let(:ai_response) { create(:ai_response, service_name: "voxa", raw_response: response_data, user: user) }

      it 'returns items count' do
        expect(ai_response.response_summary).to eq("Generated 3 content items")
      end
    end

    context 'with unknown service' do
      let(:ai_response) { create(:ai_response, service_name: "unknown", raw_response: { data: "test" }, user: user) }

      it 'returns unknown service message' do
        expect(ai_response.response_summary).to eq("Unknown service")
      end
    end

    context 'with invalid JSON' do
      let(:ai_response) { create(:ai_response, raw_response: "invalid", user: user) }

      it 'returns invalid JSON message' do
        expect(ai_response.response_summary).to eq("Invalid JSON")
      end
    end
  end
end
