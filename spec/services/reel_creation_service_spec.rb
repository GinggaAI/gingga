require 'rails_helper'

RSpec.describe ReelCreationService do
  let(:user) { create(:user) }
  let(:valid_template) { "solo_avatars" }
  let(:valid_params) do
    {
      template: valid_template,
      title: "Test Reel",
      description: "Test description",
      category: "educational",
      format: "vertical",
      story_content: "Test story content",
      music_preference: "upbeat",
      style_preference: "modern",
      use_ai_avatar: false,
      additional_instructions: "Test instructions"
    }
  end

  describe '#initialize' do
    context 'with all parameters' do
      let(:service) { described_class.new(user: user, template: valid_template, params: valid_params) }

      it 'initializes with user, template, and params' do
        expect(service.instance_variable_get(:@user)).to eq(user)
        expect(service.instance_variable_get(:@template)).to eq(valid_template)
        expect(service.instance_variable_get(:@params)).to eq(valid_params)
      end
    end

    context 'with minimal parameters' do
      let(:service) { described_class.new(user: user) }

      it 'initializes with user only' do
        expect(service.instance_variable_get(:@user)).to eq(user)
        expect(service.instance_variable_get(:@template)).to be_nil
        expect(service.instance_variable_get(:@params)).to be_nil
      end
    end

    context 'with partial parameters' do
      let(:service) { described_class.new(user: user, template: valid_template) }

      it 'initializes with user and template' do
        expect(service.instance_variable_get(:@user)).to eq(user)
        expect(service.instance_variable_get(:@template)).to eq(valid_template)
        expect(service.instance_variable_get(:@params)).to be_nil
      end
    end
  end

  describe '#initialize_reel' do
    context 'with valid template' do
      let(:service) { described_class.new(user: user, template: valid_template) }

      it 'delegates to the appropriate template service' do
        expect(Reels::SoloAvatarsCreationService).to receive(:new)
          .with(user: user, template: valid_template)
          .and_return(double(initialize_reel: { success: true, reel: double, error: nil }))

        result = service.initialize_reel

        expect(result[:success]).to be true
      end

      it 'returns success result from template service' do
        mock_reel = double('reel')
        mock_service = double('service', initialize_reel: { success: true, reel: mock_reel, error: nil })
        allow(Reels::SoloAvatarsCreationService).to receive(:new).and_return(mock_service)

        result = service.initialize_reel

        expect(result[:success]).to be true
        expect(result[:reel]).to eq(mock_reel)
        expect(result[:error]).to be_nil
      end
    end

    context 'with invalid template' do
      let(:invalid_template) { "invalid_template" }
      let(:service) { described_class.new(user: user, template: invalid_template) }

      it 'returns failure result' do
        result = service.initialize_reel

        expect(result[:success]).to be false
        expect(result[:reel]).to be_nil
        expect(result[:error]).to eq("Invalid template")
      end

      it 'does not call any template service' do
        expect(Reels::SoloAvatarsCreationService).not_to receive(:new)
        expect(Reels::AvatarAndVideoCreationService).not_to receive(:new)
        expect(Reels::NarrationOver7ImagesCreationService).not_to receive(:new)
        expect(Reels::OneToThreeVideosCreationService).not_to receive(:new)

        service.initialize_reel
      end
    end

    context 'with nil template' do
      let(:service) { described_class.new(user: user, template: nil) }

      it 'returns failure result' do
        result = service.initialize_reel

        expect(result[:success]).to be false
        expect(result[:reel]).to be_nil
        expect(result[:error]).to eq("Invalid template")
      end
    end

    context 'with each valid template type' do
      let(:templates_and_services) do
        {
          "solo_avatars" => Reels::SoloAvatarsCreationService,
          "avatar_and_video" => Reels::AvatarAndVideoCreationService,
          "narration_over_7_images" => Reels::NarrationOver7ImagesCreationService,
          "one_to_three_videos" => Reels::OneToThreeVideosCreationService
        }
      end

      it 'delegates to the correct service class for each template' do
        templates_and_services.each do |template, service_class|
          service = described_class.new(user: user, template: template)
          mock_service_instance = double('service', initialize_reel: { success: true, reel: double, error: nil })
          
          expect(service_class).to receive(:new).with(user: user, template: template).and_return(mock_service_instance)
          
          result = service.initialize_reel
          expect(result[:success]).to be true
        end
      end
    end
  end

  describe '#call' do
    context 'when params are not provided' do
      let(:service) { described_class.new(user: user, template: valid_template) }

      it 'returns failure result with appropriate error message' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:reel]).to be_nil
        expect(result[:error]).to eq("No parameters provided")
      end
    end

    context 'when params are empty' do
      let(:service) { described_class.new(user: user, params: {}) }

      it 'returns failure result with appropriate error message' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:reel]).to be_nil
        expect(result[:error]).to eq("No parameters provided")
      end
    end

    context 'with valid parameters' do
      let(:service) { described_class.new(user: user, params: valid_params) }

      it 'extracts template from params and delegates to appropriate service' do
        mock_reel = double('reel')
        mock_service = double('service', call: { success: true, reel: mock_reel, error: nil })
        
        expect(Reels::SoloAvatarsCreationService).to receive(:new)
          .with(user: user, params: valid_params)
          .and_return(mock_service)

        result = service.call

        expect(result[:success]).to be true
        expect(result[:reel]).to eq(mock_reel)
        expect(result[:error]).to be_nil
      end
    end

    context 'with invalid template in params' do
      let(:invalid_params) { valid_params.merge(template: "invalid_template") }
      let(:service) { described_class.new(user: user, params: invalid_params) }

      it 'returns failure result' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:reel]).to be_nil
        expect(result[:error]).to eq("Invalid template")
      end
    end

    context 'with missing template in params' do
      let(:params_without_template) { valid_params.except(:template) }
      let(:service) { described_class.new(user: user, params: params_without_template) }

      it 'returns failure result' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:reel]).to be_nil
        expect(result[:error]).to eq("Invalid template")
      end
    end

    context 'with each valid template type' do
      let(:templates_and_services) do
        {
          "solo_avatars" => Reels::SoloAvatarsCreationService,
          "avatar_and_video" => Reels::AvatarAndVideoCreationService,
          "narration_over_7_images" => Reels::NarrationOver7ImagesCreationService,
          "one_to_three_videos" => Reels::OneToThreeVideosCreationService
        }
      end

      it 'delegates to the correct service class for each template' do
        templates_and_services.each do |template, service_class|
          params = valid_params.merge(template: template)
          service = described_class.new(user: user, params: params)
          mock_service_instance = double('service', call: { success: true, reel: double, error: nil })
          
          expect(service_class).to receive(:new).with(user: user, params: params).and_return(mock_service_instance)
          
          result = service.call
          expect(result[:success]).to be true
        end
      end
    end
  end

  describe '#template_service_for' do
    let(:service) { described_class.new(user: user) }

    it 'returns correct service class for solo_avatars' do
      result = service.send(:template_service_for, "solo_avatars")
      expect(result).to eq(Reels::SoloAvatarsCreationService)
    end

    it 'returns correct service class for avatar_and_video' do
      result = service.send(:template_service_for, "avatar_and_video")
      expect(result).to eq(Reels::AvatarAndVideoCreationService)
    end

    it 'returns correct service class for narration_over_7_images' do
      result = service.send(:template_service_for, "narration_over_7_images")
      expect(result).to eq(Reels::NarrationOver7ImagesCreationService)
    end

    it 'returns correct service class for one_to_three_videos' do
      result = service.send(:template_service_for, "one_to_three_videos")
      expect(result).to eq(Reels::OneToThreeVideosCreationService)
    end

    it 'returns nil for invalid template' do
      result = service.send(:template_service_for, "invalid_template")
      expect(result).to be_nil
    end

    it 'returns nil for nil template' do
      result = service.send(:template_service_for, nil)
      expect(result).to be_nil
    end
  end

  describe '#valid_template?' do
    let(:service) { described_class.new(user: user) }

    context 'with valid templates' do
      it 'returns true for solo_avatars' do
        expect(service.send(:valid_template?, "solo_avatars")).to be true
      end

      it 'returns true for avatar_and_video' do
        expect(service.send(:valid_template?, "avatar_and_video")).to be true
      end

      it 'returns true for narration_over_7_images' do
        expect(service.send(:valid_template?, "narration_over_7_images")).to be true
      end

      it 'returns true for one_to_three_videos' do
        expect(service.send(:valid_template?, "one_to_three_videos")).to be true
      end
    end

    context 'with invalid templates' do
      it 'returns false for invalid template string' do
        expect(service.send(:valid_template?, "invalid_template")).to be false
      end

      it 'returns false for nil' do
        expect(service.send(:valid_template?, nil)).to be false
      end

      it 'returns false for empty string' do
        expect(service.send(:valid_template?, "")).to be false
      end

      it 'returns false for integer' do
        expect(service.send(:valid_template?, 123)).to be false
      end
    end
  end

  describe 'result helper methods' do
    let(:service) { described_class.new(user: user) }

    describe '#success_result' do
      it 'returns hash with success true and provided reel' do
        mock_reel = double('reel')
        result = service.send(:success_result, mock_reel)

        expect(result).to eq({
          success: true,
          reel: mock_reel,
          error: nil
        })
      end
    end

    describe '#failure_result' do
      it 'returns hash with success false and error message' do
        error_message = "Test error"
        result = service.send(:failure_result, error_message)

        expect(result).to eq({
          success: false,
          reel: nil,
          error: error_message
        })
      end

      it 'handles different error message types' do
        result = service.send(:failure_result, "Another error")

        expect(result[:success]).to be false
        expect(result[:reel]).to be_nil
        expect(result[:error]).to eq("Another error")
      end
    end
  end

  describe 'private method visibility' do
    let(:service) { described_class.new(user: user) }

    it 'makes template_service_for private' do
      expect(service.private_methods).to include(:template_service_for)
    end

    it 'makes valid_template? private' do
      expect(service.private_methods).to include(:valid_template?)
    end

    it 'makes success_result private' do
      expect(service.private_methods).to include(:success_result)
    end

    it 'makes failure_result private' do
      expect(service.private_methods).to include(:failure_result)
    end
  end

  describe 'integration testing' do
    context 'with real service classes' do
      let(:service) { described_class.new(user: user, params: valid_params) }

      it 'calls the actual template service and returns a result' do
        result = service.call

        # The service should return a proper result structure
        expect(result).to have_key(:success)
        expect(result).to have_key(:reel)
        
        if result[:success]
          expect(result[:reel]).to be_a(Reel)
          expect(result[:reel]).to be_persisted
          expect(result[:reel].template).to eq(valid_template)
          expect(result[:error]).to be_nil
        else
          expect(result[:error]).to be_present
        end
      end

      it 'creates reel with expected base attributes when successful' do
        result = service.call

        expect(result[:reel]).to be_a(Reel)
        reel = result[:reel]
        expect(reel.user).to eq(user)
        expect(reel.template).to eq(valid_template)
        expect(reel.status).to eq("draft")
        
        if result[:success]
          expect(reel.title).to eq(valid_params[:title])
          expect(reel.description).to eq(valid_params[:description])
        end
      end
    end
  end

  describe 'edge cases and error handling' do
    context 'when template service raises an exception' do
      let(:service) { described_class.new(user: user, params: valid_params) }

      it 'allows exceptions to bubble up' do
        allow(Reels::SoloAvatarsCreationService).to receive(:new).and_raise(StandardError, "Service error")

        expect { service.call }.to raise_error(StandardError, "Service error")
      end
    end

    context 'when template service returns unexpected result format' do
      let(:service) { described_class.new(user: user, params: valid_params) }

      it 'passes through the result as-is' do
        unexpected_result = { custom: "format" }
        mock_service = double('service', call: unexpected_result)
        allow(Reels::SoloAvatarsCreationService).to receive(:new).and_return(mock_service)

        result = service.call

        expect(result).to eq(unexpected_result)
      end
    end

    context 'with whitespace in template' do
      let(:template_with_whitespace) { "  solo_avatars  " }
      let(:params_with_whitespace) { valid_params.merge(template: template_with_whitespace) }
      let(:service) { described_class.new(user: user, params: params_with_whitespace) }

      it 'treats whitespace template as invalid' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Invalid template")
      end
    end
  end
end