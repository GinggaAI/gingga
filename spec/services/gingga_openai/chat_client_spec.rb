require 'rails_helper'
require 'webmock/rspec'

RSpec.describe GinggaOpenAI::ChatClient, type: :service do
  let(:user) { create(:user) }
  let(:model) { 'gpt-4o-mini' }
  let(:temperature) { 0.4 }
  let(:timeout) { 60 }
  let(:access_token) { 'sk-test_openai_token_123' }
  let(:system_message) { 'You are a helpful assistant.' }
  let(:user_message) { 'Hello, how are you?' }

  subject { described_class.new(user: user, model: model, temperature: temperature, timeout: timeout) }

  before do
    allow(GinggaOpenAI::ClientForUser).to receive(:access_token_for).with(user).and_return(access_token)
  end

  describe '#initialize' do
    it 'initializes with default values' do
      client = described_class.new(user: user)
      expect(client.instance_variable_get(:@model)).to eq('gpt-4o-mini')
      expect(client.instance_variable_get(:@temperature)).to eq(0.4)
    end

    it 'initializes with custom values' do
      client = described_class.new(user: user, model: 'gpt-4', temperature: 0.7, timeout: 120)
      expect(client.instance_variable_get(:@model)).to eq('gpt-4')
      expect(client.instance_variable_get(:@temperature)).to eq(0.7)
    end

    it 'creates OpenAI client with correct parameters' do
      expect(::OpenAI::Client).to receive(:new).with(
        access_token: access_token,
        request_timeout: timeout
      )
      described_class.new(user: user, timeout: timeout)
    end
  end

  describe '#chat!' do
    let(:mock_openai_client) { instance_double(::OpenAI::Client) }
    let(:successful_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => '{"response": "Hello! I am doing well, thank you for asking."}'
            }
          }
        ]
      }
    end

    before do
      allow(::OpenAI::Client).to receive(:new).and_return(mock_openai_client)
    end

    context 'when API call is successful' do
      before do
        allow(mock_openai_client).to receive(:chat).with(
          parameters: {
            model: model,
            temperature: temperature,
            response_format: { type: "json_object" },
            messages: [
              { role: "system", content: system_message },
              { role: "user", content: user_message }
            ]
          }
        ).and_return(successful_response)
      end

      it 'returns the content from OpenAI response' do
        result = subject.chat!(system: system_message, user: user_message)
        expect(result).to eq('{"response": "Hello! I am doing well, thank you for asking."}')
      end

      it 'sends correct parameters to OpenAI' do
        expect(mock_openai_client).to receive(:chat).with(
          parameters: {
            model: model,
            temperature: temperature,
            response_format: { type: "json_object" },
            messages: [
              { role: "system", content: system_message },
              { role: "user", content: user_message }
            ]
          }
        )
        subject.chat!(system: system_message, user: user_message)
      end
    end

    context 'when OpenAI returns empty response' do
      let(:empty_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => ''
              }
            }
          ]
        }
      end

      before do
        allow(mock_openai_client).to receive(:chat).and_return(empty_response)
      end

      it 'raises error for empty content' do
        expect { subject.chat!(system: system_message, user: user_message) }
          .to raise_error('OpenAI empty response')
      end
    end

    context 'when OpenAI returns nil content' do
      let(:nil_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => nil
              }
            }
          ]
        }
      end

      before do
        allow(mock_openai_client).to receive(:chat).and_return(nil_response)
      end

      it 'raises error for nil content' do
        expect { subject.chat!(system: system_message, user: user_message) }
          .to raise_error('OpenAI empty response')
      end
    end

    context 'when Faraday::TimeoutError occurs' do
      before do
        allow(mock_openai_client).to receive(:chat)
          .and_raise(Faraday::TimeoutError.new('Request timeout'))
          .and_raise(Faraday::TimeoutError.new('Request timeout'))
          .and_raise(Faraday::TimeoutError.new('Request timeout'))
      end

      it 'retries up to 3 times with exponential backoff' do
        allow(subject).to receive(:sleep)
        allow(Rails.logger).to receive(:warn)

        expect { subject.chat!(system: system_message, user: user_message) }
          .to raise_error('OpenAI API timeout after 3 attempts. Please check your network connection and try again.')
      end

      context 'when retry succeeds' do
        before do
          allow(mock_openai_client).to receive(:chat)
            .and_raise(Faraday::TimeoutError.new('Request timeout'))
            .and_return(successful_response)
        end

        it 'returns successful response after retry' do
          allow(subject).to receive(:sleep)
          allow(Rails.logger).to receive(:warn)

          result = subject.chat!(system: system_message, user: user_message)
          expect(result).to eq('{"response": "Hello! I am doing well, thank you for asking."}')
        end
      end
    end

    context 'when Faraday::ConnectionFailed occurs' do
      before do
        allow(mock_openai_client).to receive(:chat)
          .and_raise(Faraday::ConnectionFailed.new('Connection failed'))
      end

      it 'raises connection error message' do
        expect { subject.chat!(system: system_message, user: user_message) }
          .to raise_error('Unable to connect to OpenAI API. Please check your network connection and API key.')
      end
    end

    context 'when other errors occur' do
      context 'with retry-able error' do
        let(:other_error) { StandardError.new('Service unavailable') }

        before do
          allow(mock_openai_client).to receive(:chat)
            .and_raise(other_error)
            .and_return(successful_response)
        end

        it 'retries once for non-timeout errors' do
          allow(Rails.logger).to receive(:warn)

          result = subject.chat!(system: system_message, user: user_message)
          expect(result).to eq('{"response": "Hello! I am doing well, thank you for asking."}')
        end
      end

      context 'with timeout error message' do
        let(:timeout_error) { StandardError.new('Request timeout occurred') }

        before do
          allow(mock_openai_client).to receive(:chat).and_raise(timeout_error)
        end

        it 'does not retry for timeout-related errors' do
          expect(Rails.logger).not_to receive(:warn)

          expect { subject.chat!(system: system_message, user: user_message) }
            .to raise_error('Request timeout occurred')
        end
      end

      context 'when retry fails' do
        let(:other_error) { StandardError.new('Service unavailable') }

        before do
          allow(mock_openai_client).to receive(:chat)
            .and_raise(other_error)
            .and_raise(other_error)
        end

        it 'raises the original error after retry' do
          allow(Rails.logger).to receive(:warn)

          expect { subject.chat!(system: system_message, user: user_message) }
            .to raise_error('Service unavailable')
        end
      end
    end

    context 'with different models' do
      let(:model) { 'gpt-4' }

      before do
        allow(mock_openai_client).to receive(:chat).and_return(successful_response)
      end

      it 'uses the specified model' do
        expect(mock_openai_client).to receive(:chat).with(
          parameters: hash_including(model: 'gpt-4')
        )
        subject.chat!(system: system_message, user: user_message)
      end
    end

    context 'with different temperature' do
      let(:temperature) { 0.8 }

      before do
        allow(mock_openai_client).to receive(:chat).and_return(successful_response)
      end

      it 'uses the specified temperature' do
        expect(mock_openai_client).to receive(:chat).with(
          parameters: hash_including(temperature: 0.8)
        )
        subject.chat!(system: system_message, user: user_message)
      end
    end

    context 'with different messages' do
      let(:custom_system) { 'You are a creative writer.' }
      let(:custom_user) { 'Write a short story.' }

      before do
        allow(mock_openai_client).to receive(:chat).and_return(successful_response)
      end

      it 'uses the specified messages' do
        expect(mock_openai_client).to receive(:chat).with(
          parameters: hash_including(
            messages: [
              { role: "system", content: custom_system },
              { role: "user", content: custom_user }
            ]
          )
        )
        subject.chat!(system: custom_system, user: custom_user)
      end
    end
  end
end
