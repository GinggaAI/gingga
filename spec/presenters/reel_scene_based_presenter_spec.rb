require 'rails_helper'

RSpec.describe ReelSceneBasedPresenter, type: :presenter do
  let(:user) { create(:user) }
  let(:reel) { create(:reel, :only_avatars, user: user) }
  let(:presenter) { described_class.new(reel: reel, current_user: user) }

  describe '#initialize' do
    it 'initializes with reel and current_user' do
      expect(presenter.reel).to eq(reel)
      expect(presenter.current_user).to eq(user)
    end

    it 'sets instance variables correctly' do
      expect(presenter.instance_variable_get(:@reel)).to eq(reel)
      expect(presenter.instance_variable_get(:@current_user)).to eq(user)
    end
  end

  describe 'page and title methods' do
    describe '#page_title' do
      it 'returns translated page title' do
        expect(I18n).to receive(:t).with("reels.scene_based.page_title").and_return("Create Scene-Based Reel")
        expect(presenter.page_title).to eq("Create Scene-Based Reel")
      end
    end

    describe '#main_title' do
      it 'returns translated main title' do
        expect(I18n).to receive(:t).with("reels.create_reel").and_return("Create Your Reel")
        expect(presenter.main_title).to eq("Create Your Reel")
      end
    end

    describe '#main_description' do
      it 'returns translated main description' do
        expect(I18n).to receive(:t).with("reels.description").and_return("Create engaging video content")
        expect(presenter.main_description).to eq("Create engaging video content")
      end
    end
  end

  describe 'tab state methods' do
    describe '#scene_based_tab_active?' do
      it 'returns true for scene-based presenter' do
        expect(presenter.scene_based_tab_active?).to be true
      end
    end

    describe '#narrative_tab_active?' do
      it 'returns false for scene-based presenter' do
        expect(presenter.narrative_tab_active?).to be false
      end
    end
  end

  describe 'tab styling methods' do
    describe '#scene_based_tab_classes' do
      it 'returns active tab CSS classes with tab-active class' do
        expected_classes = "flex-1 px-4 py-2 text-center rounded-md font-medium transition-colors tab-active"
        expect(presenter.scene_based_tab_classes).to eq(expected_classes)
      end
    end

    describe '#narrative_tab_classes' do
      it 'returns inactive tab CSS classes' do
        expected_classes = "flex-1 px-4 py-2 text-center rounded-md font-medium transition-colors text-gray-600 hover:text-gray-900"
        expect(presenter.narrative_tab_classes).to eq(expected_classes)
      end
    end
  end

  describe 'error handling methods' do
    describe '#has_errors?' do
      context 'when reel has no errors' do
        it 'returns false' do
          expect(presenter.has_errors?).to be false
        end
      end

      context 'when reel has errors' do
        before do
          reel.errors.add(:title, "can't be blank")
        end

        it 'returns true' do
          expect(presenter.has_errors?).to be true
        end
      end
    end

    describe '#error_title' do
      it 'returns translated error title' do
        expect(I18n).to receive(:t).with("reels.errors.fix_following").and_return("Please fix the following errors:")
        expect(presenter.error_title).to eq("Please fix the following errors:")
      end
    end

    describe '#error_messages' do
      before do
        reel.errors.add(:title, "can't be blank")
        reel.errors.add(:description, "is too short")
      end

      it 'returns full error messages from reel' do
        expected_messages = [ "Title can't be blank", "Description is too short" ]
        allow(reel.errors).to receive(:full_messages).and_return(expected_messages)

        expect(presenter.error_messages).to eq(expected_messages)
      end
    end
  end

  describe 'basic info section methods' do
    describe '#basic_info_title' do
      it 'returns translated basic info title' do
        expect(I18n).to receive(:t).with("reels.basic_info.title").and_return("Basic Information")
        expect(presenter.basic_info_title).to eq("Basic Information")
      end
    end

    describe '#basic_info_description' do
      it 'returns translated basic info description' do
        expect(I18n).to receive(:t).with("reels.basic_info.description").and_return("Tell us about your reel")
        expect(presenter.basic_info_description).to eq("Tell us about your reel")
      end
    end

    describe '#title_label' do
      it 'returns translated title label' do
        expect(I18n).to receive(:t).with("reels.fields.title").and_return("Title")
        expect(presenter.title_label).to eq("Title")
      end
    end

    describe '#title_placeholder' do
      it 'returns translated title placeholder' do
        expect(I18n).to receive(:t).with("reels.placeholders.title").and_return("Enter reel title...")
        expect(presenter.title_placeholder).to eq("Enter reel title...")
      end
    end

    describe '#description_label' do
      it 'returns translated description label' do
        expect(I18n).to receive(:t).with("reels.fields.description").and_return("Description")
        expect(presenter.description_label).to eq("Description")
      end
    end

    describe '#description_placeholder' do
      it 'returns translated description placeholder' do
        expect(I18n).to receive(:t).with("reels.placeholders.description").and_return("Describe your reel...")
        expect(presenter.description_placeholder).to eq("Describe your reel...")
      end
    end
  end

  describe 'AI avatar section methods' do
    describe '#ai_avatar_title' do
      it 'returns translated AI avatar title' do
        expect(I18n).to receive(:t).with("reels.ai_avatar.title").and_return("AI Avatars")
        expect(presenter.ai_avatar_title).to eq("AI Avatars")
      end
    end

    describe '#ai_avatar_description' do
      it 'returns translated AI avatar description' do
        expect(I18n).to receive(:t).with("reels.ai_avatar.description").and_return("Choose AI-generated avatars")
        expect(presenter.ai_avatar_description).to eq("Choose AI-generated avatars")
      end
    end

    describe '#use_ai_avatars_label' do
      it 'returns translated use AI avatars label' do
        expect(I18n).to receive(:t).with("reels.ai_avatar.use_ai_avatars").and_return("Use AI Avatars")
        expect(presenter.use_ai_avatars_label).to eq("Use AI Avatars")
      end
    end

    describe '#use_ai_avatars_description' do
      it 'returns translated use AI avatars description' do
        expect(I18n).to receive(:t).with("reels.ai_avatar.enable_description").and_return("Enable AI-generated avatars")
        expect(presenter.use_ai_avatars_description).to eq("Enable AI-generated avatars")
      end
    end
  end

  describe 'scene breakdown section methods' do
    describe '#scene_breakdown_title' do
      it 'returns translated scene breakdown title' do
        expect(I18n).to receive(:t).with("reels.scene_breakdown.title").and_return("Scene Breakdown")
        expect(presenter.scene_breakdown_title).to eq("Scene Breakdown")
      end
    end

    describe '#scene_breakdown_description' do
      it 'returns translated scene breakdown description' do
        expect(I18n).to receive(:t).with("reels.scene_breakdown.description").and_return("Define your scenes")
        expect(presenter.scene_breakdown_description).to eq("Define your scenes")
      end
    end

    describe '#scene_count' do
      it 'returns fixed count of 3 scenes' do
        expect(presenter.scene_count).to eq(3)
      end
    end

    describe '#scenes_label' do
      it 'returns translated scenes label with count' do
        expect(I18n).to receive(:t).with("reels.scene_breakdown.scenes_count", count: 3).and_return("3 Scenes")
        expect(presenter.scenes_label).to eq("3 Scenes")
      end
    end

    describe '#add_scene_label' do
      it 'returns translated add scene label' do
        expect(I18n).to receive(:t).with("reels.scene_breakdown.add_scene").and_return("Add Scene")
        expect(presenter.add_scene_label).to eq("Add Scene")
      end
    end
  end

  describe 'additional instructions section methods' do
    describe '#additional_instructions_title' do
      it 'returns translated additional instructions title' do
        expect(I18n).to receive(:t).with("reels.additional_instructions.title").and_return("Additional Instructions")
        expect(presenter.additional_instructions_title).to eq("Additional Instructions")
      end
    end

    describe '#additional_instructions_description' do
      it 'returns translated additional instructions description' do
        expect(I18n).to receive(:t).with("reels.additional_instructions.description").and_return("Any special requirements?")
        expect(presenter.additional_instructions_description).to eq("Any special requirements?")
      end
    end

    describe '#style_direction_label' do
      it 'returns translated style direction label' do
        expect(I18n).to receive(:t).with("reels.additional_instructions.style_direction").and_return("Style Direction")
        expect(presenter.style_direction_label).to eq("Style Direction")
      end
    end

    describe '#style_direction_placeholder' do
      it 'returns translated style direction placeholder' do
        expect(I18n).to receive(:t).with("reels.placeholders.additional_instructions").and_return("Any additional instructions...")
        expect(presenter.style_direction_placeholder).to eq("Any additional instructions...")
      end
    end
  end

  describe 'form submission methods' do
    describe '#submit_button_label' do
      it 'returns translated submit button label' do
        expect(I18n).to receive(:t).with("reels.submit.scene_based").and_return("Create Scene-Based Reel")
        expect(presenter.submit_button_label).to eq("Create Scene-Based Reel")
      end
    end

    describe '#form_data_attributes' do
      it 'returns form data attributes with controller and scene count' do
        expected_attributes = {
          controller: "scene-list",
          scene_list_scene_count_value: 3
        }
        expect(presenter.form_data_attributes).to eq(expected_attributes)
      end
    end
  end

  describe '#scene_data_for' do
    context 'when reel has scenes' do
      let!(:scene) do
        reel.reel_scenes.create!(
          scene_number: 1,
          avatar_id: "test_avatar",
          voice_id: "test_voice",
          script: "Test script"
        )
      end

      it 'returns scene attributes for valid index' do
        scene_data = presenter.scene_data_for(0)
        expect(scene_data["scene_number"]).to eq(1)
        expect(scene_data["avatar_id"]).to eq("test_avatar")
        expect(scene_data["voice_id"]).to eq("test_voice")
        expect(scene_data["script"]).to eq("Test script")
      end

      it 'returns empty hash for invalid index' do
        scene_data = presenter.scene_data_for(99)
        expect(scene_data).to eq({})
      end
    end

    context 'when reel has no scenes' do
      it 'returns empty hash' do
        scene_data = presenter.scene_data_for(0)
        expect(scene_data).to eq({})
      end
    end
  end

  describe 'accessor methods' do
    describe '#reel' do
      it 'is readable' do
        expect(presenter.reel).to eq(reel)
      end

      it 'cannot be written directly' do
        expect { presenter.reel = double('other_reel') }.to raise_error(NoMethodError)
      end
    end

    describe '#current_user' do
      it 'is readable' do
        expect(presenter.current_user).to eq(user)
      end

      it 'cannot be written directly' do
        expect { presenter.current_user = double('other_user') }.to raise_error(NoMethodError)
      end
    end
  end

  describe 'integration with different reel states' do
    context 'with reel that has validation errors' do
      before do
        reel.errors.add(:title, "can't be blank")
        reel.errors.add(:description, "is required")
      end

      it 'correctly identifies presence of errors' do
        expect(presenter.has_errors?).to be true
      end

      it 'returns all error messages' do
        expected_messages = [ "Title can't be blank", "Description is required" ]
        allow(reel.errors).to receive(:full_messages).and_return(expected_messages)

        expect(presenter.error_messages).to match_array(expected_messages)
      end
    end

    context 'with different reel templates' do
      let(:video_reel) { create(:reel, :avatar_and_video, user: user) }
      let(:video_presenter) { described_class.new(reel: video_reel, current_user: user) }

      it 'works with different reel templates' do
        expect(video_presenter.scene_based_tab_active?).to be true
        expect(video_presenter.narrative_tab_active?).to be false
        expect(video_presenter.scene_count).to eq(3)
      end
    end

    context 'with different users' do
      let(:another_user) { create(:user) }
      let(:another_presenter) { described_class.new(reel: reel, current_user: another_user) }

      it 'correctly sets current_user regardless of reel ownership' do
        expect(another_presenter.current_user).to eq(another_user)
        expect(another_presenter.reel.user).to eq(user) # reel still belongs to original user
      end
    end
  end

  describe 'CSS and styling consistency' do
    it 'returns consistent CSS classes for active tab' do
      classes = presenter.scene_based_tab_classes
      expect(classes).to include('flex-1', 'px-4', 'py-2', 'text-center', 'rounded-md', 'font-medium', 'transition-colors', 'tab-active')
    end

    it 'returns consistent CSS classes for inactive tab' do
      classes = presenter.narrative_tab_classes
      expect(classes).to include('flex-1', 'px-4', 'py-2', 'text-center', 'rounded-md', 'font-medium', 'transition-colors', 'text-gray-600', 'hover:text-gray-900')
    end
  end

  describe 'I18n integration' do
    around do |example|
      original_locale = I18n.locale
      I18n.locale = :en
      example.run
      I18n.locale = original_locale
    end

    it 'calls I18n.t with correct keys for all translation methods' do
      translation_methods = [
        [ :page_title, "reels.scene_based.page_title" ],
        [ :main_title, "reels.create_reel" ],
        [ :main_description, "reels.description" ],
        [ :error_title, "reels.errors.fix_following" ],
        [ :basic_info_title, "reels.basic_info.title" ],
        [ :basic_info_description, "reels.basic_info.description" ],
        [ :title_label, "reels.fields.title" ],
        [ :title_placeholder, "reels.placeholders.title" ],
        [ :description_label, "reels.fields.description" ],
        [ :description_placeholder, "reels.placeholders.description" ],
        [ :ai_avatar_title, "reels.ai_avatar.title" ],
        [ :ai_avatar_description, "reels.ai_avatar.description" ],
        [ :use_ai_avatars_label, "reels.ai_avatar.use_ai_avatars" ],
        [ :use_ai_avatars_description, "reels.ai_avatar.enable_description" ],
        [ :scene_breakdown_title, "reels.scene_breakdown.title" ],
        [ :scene_breakdown_description, "reels.scene_breakdown.description" ],
        [ :add_scene_label, "reels.scene_breakdown.add_scene" ],
        [ :additional_instructions_title, "reels.additional_instructions.title" ],
        [ :additional_instructions_description, "reels.additional_instructions.description" ],
        [ :style_direction_label, "reels.additional_instructions.style_direction" ],
        [ :style_direction_placeholder, "reels.placeholders.additional_instructions" ],
        [ :submit_button_label, "reels.submit.scene_based" ]
      ]

      translation_methods.each do |method_name, i18n_key|
        expect(I18n).to receive(:t).with(i18n_key).and_return("translated_value")
        result = presenter.send(method_name)
        expect(result).to eq("translated_value")
      end
    end

    it 'calls I18n.t with parameters for scenes_label' do
      expect(I18n).to receive(:t).with("reels.scene_breakdown.scenes_count", count: 3).and_return("3 Scenes")
      result = presenter.scenes_label
      expect(result).to eq("3 Scenes")
    end
  end

  describe 'edge cases and error handling' do
    context 'when reel is nil' do
      let(:nil_presenter) { described_class.new(reel: nil, current_user: user) }

      it 'raises error when accessing reel methods' do
        expect { nil_presenter.has_errors? }.to raise_error(NoMethodError)
      end
    end

    context 'when current_user is nil' do
      let(:nil_user_presenter) { described_class.new(reel: reel, current_user: nil) }

      it 'still initializes correctly' do
        expect(nil_user_presenter.current_user).to be_nil
        expect(nil_user_presenter.reel).to eq(reel)
      end

      it 'still returns expected values for non-user-dependent methods' do
        expect(nil_user_presenter.scene_based_tab_active?).to be true
        expect(nil_user_presenter.narrative_tab_active?).to be false
        expect(nil_user_presenter.scene_count).to eq(3)
      end
    end
  end

  describe 'avatar selection methods' do
    describe '#avatars_for_select' do
      context 'when user has active avatars' do
        let!(:avatar1) { create(:avatar, user: user, name: 'John Doe', avatar_id: 'avatar_123', status: 'active') }
        let!(:avatar2) { create(:avatar, user: user, name: 'Jane Smith', avatar_id: 'avatar_456', status: 'active') }
        let!(:inactive_avatar) { create(:avatar, user: user, name: 'Inactive Avatar', avatar_id: 'avatar_789', status: 'inactive') }

        it 'returns array of [name, avatar_id] pairs for active avatars only' do
          expected_avatars = [
            [ 'John Doe', 'avatar_123' ],
            [ 'Jane Smith', 'avatar_456' ]
          ]
          expect(presenter.avatars_for_select).to match_array(expected_avatars)
        end
      end

      context 'when user has no active avatars' do
        it 'returns empty array' do
          expect(presenter.avatars_for_select).to eq([])
        end
      end
    end

    describe '#has_avatars?' do
      context 'when user has active avatars' do
        let!(:avatar) { create(:avatar, user: user, status: 'active') }

        it 'returns true' do
          expect(presenter.has_avatars?).to be true
        end
      end

      context 'when user has only inactive avatars' do
        let!(:avatar) { create(:avatar, user: user, status: 'inactive') }

        it 'returns false' do
          expect(presenter.has_avatars?).to be false
        end
      end

      context 'when user has no avatars' do
        it 'returns false' do
          expect(presenter.has_avatars?).to be false
        end
      end
    end

    describe '#no_avatars_message' do
      it 'returns translated no avatars message' do
        expect(I18n).to receive(:t).with("reels.scene_based.no_avatars_message").and_return("No avatars available.")
        expect(presenter.no_avatars_message).to eq("No avatars available.")
      end
    end
  end

  describe 'voice selection methods' do
    describe '#voices_for_select' do
      context 'when user has active voices' do
        let!(:voice1) { create(:voice, user: user, name: 'Emma Watson', voice_id: 'voice_123', active: true) }
        let!(:voice2) { create(:voice, user: user, name: 'Morgan Freeman', voice_id: 'voice_456', active: true) }
        let!(:inactive_voice) { create(:voice, user: user, name: 'Inactive Voice', voice_id: 'voice_789', active: false) }

        it 'returns array of [name, voice_id] pairs for active voices only' do
          expected_voices = [
            [ 'Emma Watson', 'voice_123' ],
            [ 'Morgan Freeman', 'voice_456' ]
          ]
          expect(presenter.voices_for_select).to match_array(expected_voices)
        end
      end

      context 'when user has no active voices' do
        it 'returns empty array' do
          expect(presenter.voices_for_select).to eq([])
        end
      end
    end

    describe '#has_voices?' do
      context 'when user has active voices' do
        let!(:voice) { create(:voice, user: user, active: true) }

        it 'returns true' do
          expect(presenter.has_voices?).to be true
        end
      end

      context 'when user has only inactive voices' do
        let!(:voice) { create(:voice, user: user, active: false) }

        it 'returns false' do
          expect(presenter.has_voices?).to be false
        end
      end

      context 'when user has no voices' do
        it 'returns false' do
          expect(presenter.has_voices?).to be false
        end
      end
    end

    describe '#no_voices_message' do
      it 'returns translated no voices message' do
        expect(I18n).to receive(:t).with("reels.scene_based.no_voices_message").and_return("No voices available.")
        expect(presenter.no_voices_message).to eq("No voices available.")
      end
    end
  end

  describe 'back navigation' do
    let(:brand) { create(:brand, user: user) }

    before do
      user.update_last_brand(brand)
    end

    describe '#back_path' do
      context 'when coming from auto_creation' do
        let(:presenter_with_referrer) do
          described_class.new(
            reel: reel,
            current_user: user,
            referrer: "http://www.example.com/#{brand.slug}/en/auto_creation"
          )
        end

        it 'returns auto_creation path' do
          expect(presenter_with_referrer.back_path).to eq("/#{brand.slug}/en/auto_creation")
        end
      end

      context 'when coming from planning' do
        let(:presenter_with_referrer) do
          described_class.new(
            reel: reel,
            current_user: user,
            referrer: "http://www.example.com/#{brand.slug}/en/planning"
          )
        end

        it 'returns planning path' do
          expect(presenter_with_referrer.back_path).to eq("/#{brand.slug}/en/planning")
        end
      end

      context 'when coming from planning with query params' do
        let(:presenter_with_referrer) do
          described_class.new(
            reel: reel,
            current_user: user,
            referrer: "http://www.example.com/#{brand.slug}/en/planning?month=2026-3"
          )
        end

        it 'returns planning path without query params' do
          expect(presenter_with_referrer.back_path).to eq("/#{brand.slug}/en/planning")
        end
      end

      context 'when coming from unknown page' do
        let(:presenter_with_referrer) do
          described_class.new(
            reel: reel,
            current_user: user,
            referrer: "http://www.example.com/#{brand.slug}/en/settings"
          )
        end

        it 'returns root path' do
          expect(presenter_with_referrer.back_path).to eq("/#{brand.slug}/en")
        end
      end

      context 'when no referrer provided' do
        let(:presenter_without_referrer) do
          described_class.new(
            reel: reel,
            current_user: user,
            referrer: nil
          )
        end

        it 'returns root path' do
          expect(presenter_without_referrer.back_path).to eq("/#{brand.slug}/en")
        end
      end

      context 'when referrer has invalid URI' do
        let(:presenter_with_invalid_referrer) do
          described_class.new(
            reel: reel,
            current_user: user,
            referrer: "not a valid uri"
          )
        end

        it 'returns root path' do
          expect(presenter_with_invalid_referrer.back_path).to eq("/#{brand.slug}/en")
        end
      end
    end
  end
end
