require 'rails_helper'

RSpec.describe Ui::PlanningComponent, type: :component do
  let(:presenter) { instance_double("PlanningPresenter") }
  let(:content_piece) do
    {
      "id" => "123",
      "title" => "Test Content",
      "platform" => "Instagram",
      "type" => "Reel",
      "status" => "draft",
      "hook" => "Test hook",
      "cta" => "Test CTA",
      "template" => "template1"
    }
  end

  let(:component) { described_class.new(content_piece: content_piece, presenter: presenter) }

  before do
    allow(presenter).to receive(:show_create_reel_button_for_content?).with(content_piece).and_return(false)
    allow(presenter).to receive(:show_beats_for_content?).with(content_piece).and_return(false)
    allow(presenter).to receive(:format_content_for_reel_creation).with(content_piece).and_return({ template: "template1" })
  end

  describe 'rendered component' do
    context 'when presenter shows create reel button' do
      before do
        allow(presenter).to receive(:show_create_reel_button_for_content?).with(content_piece).and_return(true)
      end

      it 'renders the create reel button section' do
        render_inline(component)

        expect(rendered_content).to include("Create Reel")
        expect(rendered_content).to include("bg-gradient-to-r from-green-50 to-blue-50")
        expect(rendered_content).to include("🎬")
        expect(rendered_content).to include("🚀")
      end
    end

    context 'when content piece has scenes' do
      let(:content_piece) do
        {
          "scenes" => [
            {
              "scene_number" => 1,
              "role" => "presenter",
              "description" => "Opening scene",
              "duration" => "10s",
              "visual" => "Close-up shot",
              "voiceover" => "Welcome to our video"
            }
          ]
        }
      end

      it 'renders scenes section' do
        render_inline(component)

        expect(rendered_content).to include("Shot Plan - Scenes")
        expect(rendered_content).to include("Scene 1 - presenter")
        expect(rendered_content).to include("Opening scene")
        expect(rendered_content).to include("10s")
        expect(rendered_content).to include("Close-up shot")
        expect(rendered_content).to include("Welcome to our video")
      end
    end

    context 'when presenter shows beats and content piece has beats' do
      let(:content_piece) do
        {
          "beats" => [
            {
              "beat_number" => 1,
              "description" => "Opening beat",
              "duration" => "5s",
              "image_prompt" => "Bright image"
            }
          ]
        }
      end

      before do
        allow(presenter).to receive(:show_beats_for_content?).with(content_piece).and_return(true)
      end

      it 'renders beats section' do
        render_inline(component)

        expect(rendered_content).to include("Shot Plan - Beats")
        expect(rendered_content).to include("Beat 1")
        expect(rendered_content).to include("Opening beat")
        expect(rendered_content).to include("5s")
        expect(rendered_content).to include("Bright image")
      end
    end

    context 'when no additional sections should be shown' do
      it 'renders minimal content' do
        render_inline(component)

        expect(rendered_content).not_to include("Create Reel")
        expect(rendered_content).not_to include("Shot Plan - Scenes")
        expect(rendered_content).not_to include("Shot Plan - Beats")
      end
    end
  end

  describe '#render_content_piece_for_calendar' do
    before do
      allow(presenter).to receive(:formatted_title_for_content).with(content_piece).and_return("Test Title")
      allow(presenter).to receive(:content_icon_for).with("Instagram", "Reel").and_return("🎬")
      allow(presenter).to receive(:status_css_classes_for).with("draft").and_return("bg-gray-100 text-gray-700")
    end

    it 'renders a calendar card with content piece information' do
      result = component.render_content_piece_for_calendar

      expect(result).to include("Test Title")
      expect(result).to include("🎬")
      expect(result).to include("bg-gray-100 text-gray-700")
      expect(result).to include('data-content-id="123"')
    end

    context 'when status is in_production' do
      let(:content_piece) do
        {
          "id" => "123",
          "title" => "Test Content",
          "platform" => "Instagram",
          "type" => "Reel",
          "status" => "in_production",
          "hook" => "This is a longer test hook that should be truncated",
          "cta" => "This is a longer test CTA that should be truncated"
        }
      end

      before do
        allow(presenter).to receive(:status_css_classes_for).with("in_production").and_return("bg-blue-100 text-blue-700")
      end

      it 'includes truncated hook and CTA information' do
        result = component.render_content_piece_for_calendar

        expect(result).to include("🎣 This is a longe...")
        expect(result).to include("📢 This is a longe...")
      end
    end
  end

  describe 'helper methods' do
    describe '#show_create_reel_button?' do
      it 'delegates to presenter' do
        expect(component.show_create_reel_button?).to eq(false)
      end
    end

    describe '#show_content_scenes?' do
      context 'when content piece has scenes' do
        let(:content_piece) { { "scenes" => [ { "scene_number" => 1 } ] } }

        it 'returns true' do
          expect(component.show_content_scenes?).to eq(true)
        end
      end

      context 'when content piece has no scenes' do
        it 'returns false' do
          expect(component.show_content_scenes?).to eq(false)
        end
      end
    end

    describe '#show_content_beats?' do
      it 'delegates to presenter' do
        expect(component.show_content_beats?).to eq(false)
      end
    end
  end
end
