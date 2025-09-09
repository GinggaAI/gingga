require 'rails_helper'

RSpec.describe Heygen::ValidateAndSyncService, type: :service do
  let(:user) { create(:user) }
  let(:group_url) { "https://api.heygen.com/v1/group/test_group" }

  subject { described_class.new(user: user) }
  let(:subject_with_limit) { described_class.new(user: user, voices_count: 5) }

  before do
    # Mock logger to avoid noise in tests
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '#initialize' do
    it 'initializes with user' do
      service = described_class.new(user: user)
      expect(service.instance_variable_get(:@user)).to eq(user)
      expect(service.instance_variable_get(:@voices_count)).to be_nil
    end

    it 'initializes with user and voices_count' do
      service = described_class.new(user: user, voices_count: 10)
      expect(service.instance_variable_get(:@user)).to eq(user)
      expect(service.instance_variable_get(:@voices_count)).to eq(10)
    end
  end

  describe '#call' do
    context 'when user has no HeyGen API token' do
      before do
        allow(user).to receive(:active_token_for).with("heygen").and_return(nil)
      end

      it 'returns failure result with appropriate error message' do
        result = subject.call

        expect(result.success?).to be false
        expect(result.data).to be_nil
        expect(result.error).to eq("No valid HeyGen API token found")
      end

      it 'logs the start of validation process' do
        expect(Rails.logger).to receive(:info).with("🔄 Starting HeyGen avatar validation for user: #{user.email}")
        subject.call
      end
    end

    context 'when user has valid HeyGen API token' do
      let(:api_token) { double('api_token', group_url: group_url) }
      let(:avatars_sync_service_instance) { double('avatars_sync_service') }
      let(:avatars_sync_result) { double('avatars_sync_result') }
      let(:voices_sync_service_instance) { double('voices_sync_service') }
      let(:voices_sync_result) { double('voices_sync_result') }

      before do
        allow(user).to receive(:active_token_for).with("heygen").and_return(api_token)
        allow(Heygen::SynchronizeAvatarsService).to receive(:new).with(user: user, group_url: group_url).and_return(avatars_sync_service_instance)
        allow(avatars_sync_service_instance).to receive(:call).and_return(avatars_sync_result)
        allow(Heygen::SynchronizeVoicesService).to receive(:new).with(user: user).and_return(voices_sync_service_instance)
        allow(voices_sync_service_instance).to receive(:call).and_return(voices_sync_result)
        
        # Mock the API token to prevent real API calls in the voices service
        allow(api_token).to receive(:encrypted_token).and_return('fake_token')
      end

      context 'when synchronization succeeds' do
        let(:avatar_count) { 5 }
        let(:voice_count) { 3 }

        before do
          # Mock avatar synchronization success
          allow(avatars_sync_result).to receive(:success?).and_return(true)
          allow(avatars_sync_result).to receive(:data).and_return({ synchronized_count: avatar_count })
          allow(avatars_sync_result).to receive(:error).and_return(nil)

          # Mock voice synchronization success
          allow(voices_sync_result).to receive(:success?).and_return(true)
          allow(voices_sync_result).to receive(:data).and_return({ synchronized_count: voice_count })
          allow(voices_sync_result).to receive(:error).and_return(nil)
        end

        context 'with group URL present' do
          it 'returns success result with group validation message key' do
            result = subject.call

            expect(result.success?).to be true
            expect(result.data[:synchronized_count]).to eq(avatar_count) # Backward compatibility
            expect(result.data[:avatar_count]).to eq(avatar_count)
            expect(result.data[:voice_count]).to eq(voice_count)
            expect(result.data[:message_key]).to eq("settings.heygen.group_validation_success")
            expect(result.error).to be_nil
          end

          it 'logs success information' do
            expect(Rails.logger).to receive(:info).with("🔗 [DEBUG] ValidateAndSyncService - group_url from token: #{group_url.inspect}")
            expect(Rails.logger).to receive(:info).with("📊 Avatar sync result: Success=true, Data=[:synchronized_count], Error=")
            expect(Rails.logger).to receive(:info).with("✅ Successfully synchronized #{avatar_count} avatars")
            expect(Rails.logger).to receive(:info).with("🎵 Voice sync result: Success=true, Data=[:synchronized_count], Error=")
            expect(Rails.logger).to receive(:info).with("✅ Successfully synchronized #{voice_count} voices")

            subject.call
          end
        end

        context 'with no group URL' do
          let(:group_url) { nil }

          it 'returns success result with regular validation message key' do
            result = subject.call

            expect(result.success?).to be true
            expect(result.data[:synchronized_count]).to eq(synchronized_count)
            expect(result.data[:message_key]).to eq("settings.heygen.validation_success")
            expect(result.error).to be_nil
          end
        end

        context 'with empty group URL' do
          let(:group_url) { "" }

          it 'returns success result with regular validation message key' do
            result = subject.call

            expect(result.success?).to be true
            expect(result.data[:message_key]).to eq("settings.heygen.validation_success")
          end
        end

        context 'when synchronized_count is missing from data' do
          before do
            allow(sync_result).to receive(:data).and_return({})
          end

          it 'defaults synchronized_count to 0' do
            result = subject.call

            expect(result.success?).to be true
            expect(result.data[:synchronized_count]).to eq(0)
            expect(result.error).to be_nil
          end

          it 'logs with count 0' do
            expect(Rails.logger).to receive(:info).with("✅ Successfully synchronized 0 avatars")
            subject.call
          end
        end

        context 'when sync_result.data is nil' do
          let(:nil_data_sync_result) { double('sync_result', success?: true, data: nil, error: nil) }

          before do
            allow(Heygen::SynchronizeAvatarsService).to receive(:new).with(user: user, group_url: group_url).and_return(sync_service_instance)
            allow(sync_service_instance).to receive(:call).and_return(nil_data_sync_result)
          end

          it 'handles nil data gracefully' do
            result = subject.call

            # The service should handle nil data gracefully
            expect(result).to respond_to(:success?)
            expect(result).to respond_to(:data)
            expect(result).to respond_to(:error)
          end
        end
      end

      context 'when synchronization fails' do
        let(:error_message) { "API connection failed" }

        before do
          allow(sync_result).to receive(:success?).and_return(false)
          allow(sync_result).to receive(:data).and_return(nil)
          allow(sync_result).to receive(:error).and_return(error_message)
        end

        it 'returns failure result with sync error message' do
          result = subject.call

          expect(result.success?).to be false
          expect(result.data).to be_nil
          expect(result.error).to eq("Validation failed: #{error_message}")
        end

        it 'logs error information' do
          expect(Rails.logger).to receive(:info).with("📊 Validation result: Success=false, Data=, Error=#{error_message}")
          expect(Rails.logger).to receive(:error).with("❌ Avatar validation failed: #{error_message}")

          subject.call
        end
      end
    end

    context 'when an exception is raised' do
      let(:exception_message) { "Connection timeout" }
      let(:api_token) { double('api_token', group_url: group_url) }

      before do
        allow(user).to receive(:active_token_for).with("heygen").and_return(api_token)
        allow(Heygen::SynchronizeAvatarsService).to receive(:new).and_raise(StandardError, exception_message)
      end

      it 'returns failure result with exception message' do
        result = subject.call

        expect(result.success?).to be false
        expect(result.data).to be_nil
        expect(result.error).to eq("Error during validation: #{exception_message}")
      end

      it 'logs error information' do
        expect(Rails.logger).to receive(:error).with("❌ Avatar validation error: #{exception_message}")

        subject.call
      end
    end

    context 'when SynchronizeAvatarsService.new raises exception' do
      let(:api_token) { double('api_token', group_url: group_url) }

      before do
        allow(user).to receive(:active_token_for).with("heygen").and_return(api_token)
        allow(Heygen::SynchronizeAvatarsService).to receive(:new).and_raise(NoMethodError, "undefined method")
      end

      it 'handles the exception gracefully' do
        result = subject.call

        expect(result.success?).to be false
        expect(result.error).to eq("Error during validation: undefined method")
      end
    end
  end

  describe 'private methods' do
    describe '#success_result' do
      it 'returns OpenStruct with success true and provided data' do
        result = subject.send(:success_result, avatar_count: 3, voice_count: 2, message_key: "test.key")

        expect(result).to be_a(OpenStruct)
        expect(result.success?).to be true
        expect(result.data[:synchronized_count]).to eq(3) # Backward compatibility
        expect(result.data[:avatar_count]).to eq(3)
        expect(result.data[:voice_count]).to eq(2)
        expect(result.data[:message_key]).to eq("test.key")
        expect(result.error).to be_nil
      end

      it 'handles different count values' do
        result = subject.send(:success_result, avatar_count: 0, voice_count: 5, message_key: "zero.key")

        expect(result.data[:synchronized_count]).to eq(0) # Avatar count for backward compatibility
        expect(result.data[:avatar_count]).to eq(0)
        expect(result.data[:voice_count]).to eq(5)
        expect(result.data[:message_key]).to eq("zero.key")
      end

      it 'handles different message keys' do
        result = subject.send(:success_result, avatar_count: 1, voice_count: 1, message_key: "settings.heygen.group_validation_success")

        expect(result.data[:message_key]).to eq("settings.heygen.group_validation_success")
      end

      it 'handles voice_error parameter' do
        result = subject.send(:success_result, avatar_count: 2, voice_count: 0, message_key: "test.key", voice_error: "Voice sync failed")

        expect(result.data[:voice_error]).to eq("Voice sync failed")
      end
    end

    describe '#failure_result' do
      it 'returns OpenStruct with success false and error message' do
        error_message = "Test error"
        result = subject.send(:failure_result, error_message)

        expect(result).to be_a(OpenStruct)
        expect(result.success?).to be false
        expect(result.data).to be_nil
        expect(result.error).to eq(error_message)
      end

      it 'handles different error messages' do
        error_message = "Different error message"
        result = subject.send(:failure_result, error_message)

        expect(result.error).to eq(error_message)
      end

      it 'handles empty error message' do
        result = subject.send(:failure_result, "")

        expect(result.error).to eq("")
      end
    end
  end

  describe 'method visibility' do
    it 'makes success_result private' do
      expect(subject.private_methods).to include(:success_result)
    end

    it 'makes failure_result private' do
      expect(subject.private_methods).to include(:failure_result)
    end
  end

  describe 'integration with dependencies' do
    let(:api_token) { double('api_token', group_url: group_url) }
    let(:sync_service_instance) { double('sync_service') }
    let(:sync_result) { double('sync_result', success?: true, data: { synchronized_count: 2 }, error: nil) }

    before do
      allow(user).to receive(:active_token_for).with("heygen").and_return(api_token)
    end

    it 'calls SynchronizeAvatarsService with correct parameters' do
      expect(Heygen::SynchronizeAvatarsService).to receive(:new).with(user: user, group_url: group_url).and_return(sync_service_instance)
      expect(sync_service_instance).to receive(:call).and_return(sync_result)

      subject.call
    end

    it 'passes group_url from API token to synchronization service' do
      different_group_url = "https://api.heygen.com/v1/group/another_group"
      api_token_with_different_url = double('api_token', group_url: different_group_url)
      allow(user).to receive(:active_token_for).with("heygen").and_return(api_token_with_different_url)

      expect(Heygen::SynchronizeAvatarsService).to receive(:new).with(user: user, group_url: different_group_url).and_return(sync_service_instance)
      expect(sync_service_instance).to receive(:call).and_return(sync_result)

      subject.call
    end
  end

  describe 'result object behavior' do
    let(:api_token) { double('api_token', group_url: group_url) }
    let(:sync_service_instance) { double('sync_service') }
    let(:sync_result) { double('sync_result', success?: true, data: { synchronized_count: 3 }, error: nil) }

    before do
      allow(user).to receive(:active_token_for).with("heygen").and_return(api_token)
      allow(Heygen::SynchronizeAvatarsService).to receive(:new).and_return(sync_service_instance)
      allow(sync_service_instance).to receive(:call).and_return(sync_result)
    end

    it 'returns result that responds to success?' do
      result = subject.call
      expect(result).to respond_to(:success?)
    end

    it 'returns result that responds to data' do
      result = subject.call
      expect(result).to respond_to(:data)
    end

    it 'returns result that responds to error' do
      result = subject.call
      expect(result).to respond_to(:error)
    end
  end

  describe 'edge cases' do
    context 'when user is nil' do
      subject { described_class.new(user: nil) }

      it 'handles nil user gracefully by returning failure result' do
        result = subject.call
        expect(result.success?).to be false
        expect(result.error).to be_present
      end
    end

    context 'when group_url contains special characters' do
      let(:special_group_url) { "https://api.heygen.com/v1/group/test%20group?id=123&type=special" }
      let(:api_token) { double('api_token', group_url: special_group_url) }
      let(:sync_service_instance) { double('sync_service') }
      let(:sync_result) { double('sync_result', success?: true, data: { synchronized_count: 1 }, error: nil) }

      before do
        allow(user).to receive(:active_token_for).with("heygen").and_return(api_token)
        allow(Heygen::SynchronizeAvatarsService).to receive(:new).and_return(sync_service_instance)
        allow(sync_service_instance).to receive(:call).and_return(sync_result)
      end

      it 'handles special characters in group_url' do
        expect(Rails.logger).to receive(:info).with("🔗 [DEBUG] ValidateAndSyncService - group_url from token: #{special_group_url.inspect}")

        result = subject.call
        expect(result.success?).to be true
      end
    end
  end
end
