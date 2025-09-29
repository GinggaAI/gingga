require 'rails_helper'

RSpec.describe Reels::OneToThreeVideosCreationService do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:template) { "one_to_three_videos" }
  let(:params) do
    {
      template: template,
      title: "Video Compilation Reel",
      description: "Test description for video compilation",
      category: "entertainment",
      format: "horizontal",
      story_content: "Video compilation content",
      music_preference: "ambient",
      style_preference: "cinematic",
      use_ai_avatar: true,
      additional_instructions: "Compile 3 videos into one reel"
    }
  end

  describe '#initialize' do
    it 'initializes with user, template, and params' do
      service = described_class.new(user: user, brand: brand, template: template, params: params)

      expect(service.instance_variable_get(:@user)).to eq(user)
      expect(service.instance_variable_get(:@template)).to eq(template)
      expect(service.instance_variable_get(:@params)).to eq(params)
    end

    context 'when template is not provided' do
      it 'allows nil template' do
        service = described_class.new(user: user, brand: brand, template: nil, params: params)

        expect(service.instance_variable_get(:@template)).to be_nil
      end
    end

    context 'when params are not provided' do
      it 'allows nil params' do
        service = described_class.new(user: user, brand: brand, template: template, params: nil)

        expect(service.instance_variable_get(:@params)).to be_nil
      end
    end
  end

  describe '#initialize_reel' do
    let(:service) { described_class.new(user: user, brand: brand, template: template) }

    it 'creates a new reel with draft status and specified template' do
      result = service.initialize_reel

      expect(result[:success]).to be true
      expect(result[:reel]).to be_a(Reel)
      expect(result[:reel].user).to eq(user)
      expect(result[:reel].template).to eq(template)
      expect(result[:reel].status).to eq("draft")
      expect(result[:error]).to be_nil
    end

    it 'saves the reel to the database' do
      expect { service.initialize_reel }.to change(Reel, :count).by(1)
    end

    it 'does not create any reel scenes by default' do
      result = service.initialize_reel

      expect(result[:reel].reel_scenes.size).to eq(0)
    end
  end

  describe '#call' do
    let(:service) { described_class.new(user: user, brand: brand, params: params) }

    context 'when creating a new reel successfully' do
      it 'creates and saves a reel with the provided parameters' do
        expect { service.call }.to change(Reel, :count).by(1)

        result = service.call
        expect(result[:success]).to be true
        expect(result[:reel]).to be_persisted
        expect(result[:reel].template).to eq(template)
        expect(result[:reel].title).to eq(params[:title])
        expect(result[:reel].description).to eq(params[:description])
        expect(result[:error]).to be_nil
      end

      it 'sets the status to draft' do
        result = service.call

        expect(result[:reel].status).to eq("draft")
      end

      it 'creates reel with correct attributes' do
        result = service.call

        expect(result[:reel].category).to eq("entertainment")
        expect(result[:reel].format).to eq("horizontal")
        expect(result[:reel].story_content).to eq("Video compilation content")
        expect(result[:reel].music_preference).to eq("ambient")
        expect(result[:reel].style_preference).to eq("cinematic")
        expect(result[:reel].use_ai_avatar).to be true
        expect(result[:reel].additional_instructions).to eq("Compile 3 videos into one reel")
      end

      it 'does not create reel scenes for this template' do
        result = service.call

        expect(result[:reel].reel_scenes.count).to eq(0)
      end
    end

    context 'when reel creation fails due to validation errors' do
      let(:invalid_params) do
        params.merge(template: "invalid_template")
      end
      let(:service) { described_class.new(user: user, brand: brand, params: invalid_params) }

      it 'returns failure result with validation error' do
        result = service.call

        expect(result[:success]).to be false
        expect(result[:reel]).to be_present
        expect(result[:reel]).not_to be_persisted
        expect(result[:error]).to be_present
      end

      it 'does not save the reel to the database' do
        expect { service.call }.not_to change(Reel, :count)
      end
    end

    context 'when title is missing' do
      let(:invalid_params) { params.except(:title) }
      let(:service) { described_class.new(user: user, brand: brand, params: invalid_params) }

      it 'still creates the reel as title is not required at creation' do
        result = service.call

        expect(result[:success]).to be true
        expect(result[:reel]).to be_persisted
        expect(result[:reel].title).to be_nil
      end
    end
  end

  describe '#setup_template_specific_fields' do
    let(:service) { described_class.new(user: user, brand: brand, template: template) }
    let(:reel) { user.reels.build(template: template, status: "draft") }

    it 'does not add any scenes for one_to_three_videos template' do
      initial_scene_count = reel.reel_scenes.size
      service.send(:setup_template_specific_fields, reel)

      expect(reel.reel_scenes.size).to eq(initial_scene_count)
    end

    it 'is a no-op method that does not modify the reel' do
      reel_attributes_before = reel.attributes.dup
      service.send(:setup_template_specific_fields, reel)

      expect(reel.attributes).to eq(reel_attributes_before)
    end

    context 'when reel already has some scenes' do
      before do
        reel.reel_scenes.build(
          scene_number: 1,
          avatar_id: "test_avatar",
          voice_id: "test_voice",
          script: "Test script"
        )
      end

      it 'does not modify existing scenes' do
        existing_scene = reel.reel_scenes.first
        service.send(:setup_template_specific_fields, reel)

        expect(existing_scene.avatar_id).to eq("test_avatar")
        expect(existing_scene.voice_id).to eq("test_voice")
        expect(existing_scene.script).to eq("Test script")
      end

      it 'does not add additional scenes' do
        initial_count = reel.reel_scenes.size
        service.send(:setup_template_specific_fields, reel)

        expect(reel.reel_scenes.size).to eq(initial_count)
      end
    end
  end

  describe '#reel_params' do
    let(:service) { described_class.new(user: user, brand: brand, params: params) }

    it 'returns the merged parameters with draft status' do
      result_params = service.send(:reel_params)

      expect(result_params[:status]).to eq("draft")
      expect(result_params[:title]).to eq(params[:title])
      expect(result_params[:template]).to eq(params[:template])
    end

    it 'calls super to get base parameters' do
      # This tests that the method properly calls the parent implementation
      base_params = params.merge(status: "draft")
      allow_any_instance_of(Reels::BaseCreationService).to receive(:reel_params).and_return(base_params)

      result = service.send(:reel_params)

      expect(result).to eq(base_params)
    end

    context 'when future video compilation fields are added' do
      # This test documents the future enhancement mentioned in comments
      it 'should be extended to include video compilation specific fields' do
        # Currently returns base_params as-is, but the method is ready for extension
        result_params = service.send(:reel_params)

        # Verify current behavior
        expect(result_params.keys).not_to include(:video_prompts)
        expect(result_params.keys).not_to include(:compilation_style)

        # This test serves as documentation for future enhancement:
        # When video compilation fields are implemented, they should be merged here
      end
    end
  end

  describe 'inheritance from BaseCreationService' do
    it 'inherits from BaseCreationService' do
      expect(described_class.superclass).to eq(Reels::BaseCreationService)
    end

    it 'responds to inherited methods' do
      service = described_class.new(user: user, brand: brand, template: template, params: params)

      expect(service).to respond_to(:initialize_reel)
      expect(service).to respond_to(:call)
    end
  end

  describe 'private method visibility' do
    let(:service) { described_class.new(user: user, brand: brand, template: template) }

    it 'makes setup_template_specific_fields private' do
      expect(service.private_methods).to include(:setup_template_specific_fields)
    end

    it 'makes reel_params private' do
      expect(service.private_methods).to include(:reel_params)
    end
  end

  describe 'integration with Reel model' do
    let(:service) { described_class.new(user: user, brand: brand, params: params) }

    it 'creates a reel that passes validation' do
      result = service.call

      expect(result[:reel]).to be_valid
    end

    it 'creates a reel with the correct template for validation' do
      result = service.call

      expect(result[:reel].template).to eq("one_to_three_videos")
      # This template doesn't require scenes, so it should be valid without them
      expect(result[:reel]).to be_valid
    end

    context 'when using different template values' do
      let(:different_template) { "one_to_three_videos" }
      let(:service) { described_class.new(user: user, brand: brand, params: params.merge(template: different_template)) }

      it 'creates reel with specified template' do
        result = service.call

        expect(result[:reel].template).to eq(different_template)
      end
    end
  end

  describe 'template-specific behavior' do
    let(:service) { described_class.new(user: user, brand: brand, params: params) }

    it 'differs from scene-based templates by not requiring scenes' do
      result = service.call

      # Unlike only_avatars or avatar_and_video templates, this one doesn't need scenes
      expect(result[:reel].reel_scenes.count).to eq(0)
      expect(result[:reel]).to be_valid
    end

    it 'is designed for video compilation workflow' do
      result = service.call

      # The reel should be ready for a video compilation process
      # rather than scene-by-scene generation
      expect(result[:reel].template).to eq("one_to_three_videos")
      expect(result[:reel].ready_for_generation?).to be true
    end
  end

  describe 'edge cases' do
    context 'when params contain valid optional fields' do
      let(:params_with_extra) do
        params.merge(
          video_url: "https://example.com/video.mp4",
          duration: 30
        )
      end
      let(:service) { described_class.new(user: user, brand: brand, params: params_with_extra) }

      it 'handles additional valid parameters gracefully' do
        result = service.call

        # The service should handle additional valid parameters
        expect(result).to have_key(:success)
        expect(result).to have_key(:reel)
      end
    end

    context 'when user is nil' do
      let(:service) { described_class.new(user: nil, params: params) }

      it 'returns failure result when trying to build reel without user' do
        result = service.call
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Brand is required")
      end
    end

    context 'when params is empty hash' do
      let(:empty_params) { {} }
      let(:service) { described_class.new(user: user, brand: brand, params: empty_params) }

      it 'attempts to create reel with minimal attributes' do
        result = service.call

        expect(result).to have_key(:success)
        expect(result).to have_key(:reel)
        expect(result[:reel].status).to eq("draft")
      end
    end
  end
end
