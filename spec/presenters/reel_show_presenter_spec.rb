require 'rails_helper'

RSpec.describe ReelShowPresenter do
  let(:user) { create(:user) }
  let(:reel) { create(:reel, user: user, status: 'draft', title: 'Test Reel', description: 'Test description', template: 'narration_over_7_images') }
  let(:presenter) { described_class.new(reel) }

  describe '#title' do
    it 'returns the reel title when present' do
      expect(presenter.title).to eq('Test Reel')
    end

    it 'returns "Untitled Reel" when title is blank' do
      reel.update!(title: '')
      expect(presenter.title).to eq('Untitled Reel')
    end

    it 'returns "Untitled Reel" when title is nil' do
      reel.update!(title: nil)
      expect(presenter.title).to eq('Untitled Reel')
    end
  end

  describe '#description' do
    it 'returns the description when present' do
      expect(presenter.description).to eq('Test description')
    end

    it 'returns nil when description is blank' do
      reel.update!(description: '')
      expect(presenter.description).to be_nil
    end
  end

  describe '#status_badge_class' do
    it 'returns correct class for draft status' do
      expect(presenter.status_badge_class).to eq('status-badge status-badge--draft')
    end

    it 'returns correct class for processing status' do
      reel.update!(status: 'processing')
      expect(presenter.status_badge_class).to eq('status-badge status-badge--processing')
    end

    it 'returns correct class for completed status' do
      reel.update!(status: 'completed')
      expect(presenter.status_badge_class).to eq('status-badge status-badge--completed')
    end

    it 'returns correct class for failed status' do
      reel.update!(status: 'failed')
      expect(presenter.status_badge_class).to eq('status-badge status-badge--failed')
    end

    it 'returns safe fallback for unknown status' do
      # Bypass validation to test fallback
      reel.update_column(:status, 'unknown')
      expect(presenter.status_badge_class).to eq('status-badge status-badge--draft')
    end
  end

  describe '#status_titleized' do
    it 'returns titleized status' do
      expect(presenter.status_titleized).to eq('Draft')
    end
  end

  describe 'conditional display methods' do
    context 'when status is completed and has video_url' do
      before do
        reel.update!(status: 'completed', video_url: 'https://example.com/video.mp4')
      end

      it 'shows video' do
        expect(presenter.show_video?).to be true
        expect(presenter.show_processing_indicator?).to be false
        expect(presenter.show_error_message?).to be false
      end
    end

    context 'when status is processing' do
      before do
        reel.update!(status: 'processing')
      end

      it 'shows processing indicator' do
        expect(presenter.show_video?).to be false
        expect(presenter.show_processing_indicator?).to be true
        expect(presenter.show_error_message?).to be false
      end
    end

    context 'when status is failed' do
      before do
        reel.update!(status: 'failed')
      end

      it 'shows error message' do
        expect(presenter.show_video?).to be false
        expect(presenter.show_processing_indicator?).to be false
        expect(presenter.show_error_message?).to be true
      end
    end
  end

  describe '#template_humanized' do
    it 'returns humanized template' do
      expect(presenter.template_humanized).to eq('Narration over 7 images')
    end
  end

  describe '#created_at_formatted' do
    it 'returns formatted creation date' do
      formatted_date = reel.created_at.strftime("%B %d, %Y at %I:%M %p")
      expect(presenter.created_at_formatted).to eq(formatted_date)
    end
  end

  describe '#duration_text' do
    it 'returns duration text when duration is present' do
      reel.update!(duration: 120)
      expect(presenter.duration_text).to eq('Duration: 120 seconds')
    end

    it 'returns nil when duration is not present' do
      reel.update!(duration: nil)
      expect(presenter.duration_text).to be_nil
    end
  end

  describe 'scene methods' do
    context 'when reel has scenes' do
      let(:reel_with_scenes) { create(:reel, user: user, template: 'only_avatars') }
      let(:presenter_with_scenes) { described_class.new(reel_with_scenes) }

      before do
        create(:reel_scene, reel: reel_with_scenes, scene_number: 1)
        create(:reel_scene, reel: reel_with_scenes, scene_number: 2)
        create(:reel_scene, reel: reel_with_scenes, scene_number: 3)
      end

      it 'returns true for has_scenes?' do
        reel_with_scenes.reload # Ensure associations are loaded
        expect(presenter_with_scenes.has_scenes?).to be true
      end

      it 'returns ordered scenes' do
        expect(presenter_with_scenes.ordered_scenes.count).to eq(3)
        expect(presenter_with_scenes.ordered_scenes.map(&:scene_number)).to eq([ 1, 2, 3 ])
      end
    end

    context 'when reel has no scenes' do
      it 'returns false for has_scenes?' do
        expect(presenter.has_scenes?).to be false
      end
    end
  end

  describe 'message methods' do
    it 'returns processing messages' do
      expect(presenter.processing_message).to eq('Your video is being generated with HeyGen...')
      expect(presenter.processing_subtitle).to include('This usually takes a few minutes')
    end

    it 'returns error message' do
      expect(presenter.error_message).to include('There was an error generating your video')
    end
  end
end
