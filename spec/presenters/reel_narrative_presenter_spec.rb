require 'rails_helper'

RSpec.describe ReelNarrativePresenter, type: :presenter do
  let(:user) { create(:user) }
  let(:reel) { create(:reel, :narration_over_7_images, user: user) }
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
        expect(I18n).to receive(:t).with("reels.narrative.page_title").and_return("Create Narrative Reel")
        expect(presenter.page_title).to eq("Create Narrative Reel")
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
      it 'returns false for narrative presenter' do
        expect(presenter.scene_based_tab_active?).to be false
      end
    end

    describe '#narrative_tab_active?' do
      it 'returns true for narrative presenter' do
        expect(presenter.narrative_tab_active?).to be true
      end
    end
  end

  describe 'tab styling methods' do
    describe '#scene_based_tab_classes' do
      it 'returns inactive tab CSS classes' do
        expected_classes = "flex-1 px-4 py-2 text-center rounded-md font-medium transition-colors text-gray-600 hover:text-gray-900"
        expect(presenter.scene_based_tab_classes).to eq(expected_classes)
      end
    end

    describe '#narrative_tab_classes' do
      it 'returns active tab CSS classes' do
        expected_classes = "flex-1 px-4 py-2 text-center rounded-md font-medium transition-colors text-white"
        expect(presenter.narrative_tab_classes).to eq(expected_classes)
      end
    end

    describe '#narrative_tab_style' do
      it 'returns active tab inline style' do
        expect(presenter.narrative_tab_style).to eq("background-color: #FFC857")
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
        expected_messages = ["Title can't be blank", "Description is too short"]
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

  describe 'narrative content section methods' do
    describe '#narrative_content_title' do
      it 'returns translated narrative content title' do
        expect(I18n).to receive(:t).with("reels.narrative.content_title").and_return("Your Story")
        expect(presenter.narrative_content_title).to eq("Your Story")
      end
    end

    describe '#narrative_content_description' do
      it 'returns translated narrative content description' do
        expect(I18n).to receive(:t).with("reels.narrative.content_description").and_return("Tell your story in your own words")
        expect(presenter.narrative_content_description).to eq("Tell your story in your own words")
      end
    end

    describe '#story_content_label' do
      it 'returns translated story content label' do
        expect(I18n).to receive(:t).with("reels.narrative.your_story").and_return("Your Story")
        expect(presenter.story_content_label).to eq("Your Story")
      end
    end

    describe '#story_content_placeholder' do
      it 'returns translated story content placeholder' do
        expect(I18n).to receive(:t).with("reels.placeholders.narration_text").and_return("Tell your story here...")
        expect(presenter.story_content_placeholder).to eq("Tell your story here...")
      end
    end
  end

  describe 'image themes section methods' do
    describe '#image_themes_title' do
      it 'returns translated image themes title' do
        expect(I18n).to receive(:t).with("reels.narrative.image_themes_title").and_return("Image Themes")
        expect(presenter.image_themes_title).to eq("Image Themes")
      end
    end

    describe '#image_themes_description' do
      it 'returns translated image themes description' do
        expect(I18n).to receive(:t).with("reels.narrative.image_themes_description").and_return("Choose themes for your images")
        expect(presenter.image_themes_description).to eq("Choose themes for your images")
      end
    end

    describe '#image_themes_label' do
      it 'returns translated image themes label' do
        expect(I18n).to receive(:t).with("reels.narrative.image_themes").and_return("Image Themes")
        expect(presenter.image_themes_label).to eq("Image Themes")
      end
    end

    describe '#image_themes_placeholder' do
      it 'returns translated image themes placeholder' do
        expect(I18n).to receive(:t).with("reels.placeholders.image_themes").and_return("nature, technology, business...")
        expect(presenter.image_themes_placeholder).to eq("nature, technology, business...")
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
        expect(I18n).to receive(:t).with("reels.submit.narrative").and_return("Create Narrative Reel")
        expect(presenter.submit_button_label).to eq("Create Narrative Reel")
      end
    end

    describe '#form_data_attributes' do
      it 'returns empty hash for form data attributes' do
        expect(presenter.form_data_attributes).to eq({})
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
        reel.errors.add(:story_content, "is required")
      end

      it 'correctly identifies presence of errors' do
        expect(presenter.has_errors?).to be true
      end

      it 'returns all error messages' do
        expected_messages = ["Title can't be blank", "Story content is required"]
        allow(reel.errors).to receive(:full_messages).and_return(expected_messages)
        
        expect(presenter.error_messages).to match_array(expected_messages)
      end
    end

    context 'with different reel templates' do
      let(:solo_reel) { create(:reel, :solo_avatars, user: user) }
      let(:solo_presenter) { described_class.new(reel: solo_reel, current_user: user) }

      it 'works with different reel templates' do
        expect(solo_presenter.narrative_tab_active?).to be true
        expect(solo_presenter.scene_based_tab_active?).to be false
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
    it 'returns consistent CSS classes for inactive tab' do
      classes = presenter.scene_based_tab_classes
      expect(classes).to include('flex-1', 'px-4', 'py-2', 'text-center', 'rounded-md', 'font-medium', 'transition-colors', 'text-gray-600', 'hover:text-gray-900')
    end

    it 'returns consistent CSS classes for active tab' do
      classes = presenter.narrative_tab_classes
      expect(classes).to include('flex-1', 'px-4', 'py-2', 'text-center', 'rounded-md', 'font-medium', 'transition-colors', 'text-white')
    end

    it 'returns consistent inline style for active tab' do
      style = presenter.narrative_tab_style
      expect(style).to match(/background-color:\s*#FFC857/)
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
        [:page_title, "reels.narrative.page_title"],
        [:main_title, "reels.create_reel"],
        [:main_description, "reels.description"],
        [:error_title, "reels.errors.fix_following"],
        [:basic_info_title, "reels.basic_info.title"],
        [:basic_info_description, "reels.basic_info.description"],
        [:title_label, "reels.fields.title"],
        [:title_placeholder, "reels.placeholders.title"],
        [:description_label, "reels.fields.description"],
        [:description_placeholder, "reels.placeholders.description"],
        [:narrative_content_title, "reels.narrative.content_title"],
        [:narrative_content_description, "reels.narrative.content_description"],
        [:story_content_label, "reels.narrative.your_story"],
        [:story_content_placeholder, "reels.placeholders.narration_text"],
        [:image_themes_title, "reels.narrative.image_themes_title"],
        [:image_themes_description, "reels.narrative.image_themes_description"],
        [:image_themes_label, "reels.narrative.image_themes"],
        [:image_themes_placeholder, "reels.placeholders.image_themes"],
        [:additional_instructions_title, "reels.additional_instructions.title"],
        [:additional_instructions_description, "reels.additional_instructions.description"],
        [:style_direction_label, "reels.additional_instructions.style_direction"],
        [:style_direction_placeholder, "reels.placeholders.additional_instructions"],
        [:submit_button_label, "reels.submit.narrative"]
      ]

      translation_methods.each do |method_name, i18n_key|
        expect(I18n).to receive(:t).with(i18n_key).and_return("translated_value")
        result = presenter.send(method_name)
        expect(result).to eq("translated_value")
      end
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
        expect(nil_user_presenter.narrative_tab_active?).to be true
        expect(nil_user_presenter.scene_based_tab_active?).to be false
      end
    end

    context 'when I18n keys are missing' do
      before do
        allow(I18n).to receive(:t).and_raise(I18n::MissingTranslationData.new(:en, :missing_key))
      end

      it 'allows I18n errors to bubble up' do
        expect { presenter.page_title }.to raise_error(I18n::MissingTranslationData)
      end
    end
  end
end