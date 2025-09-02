require 'rails_helper'

RSpec.describe Creas::ContentItemFormatter, type: :service do
  let(:content_item) { create(:creas_content_item, :with_narration) }
  let(:formatter) { described_class.new(content_item) }

  describe ".call" do
    it "returns formatted hash for content item" do
      result = described_class.call(content_item)
      expect(result).to be_a(Hash)
      expect(result[:id]).to eq(content_item.content_id)
    end
  end

  describe "#to_h" do
    context "with valid content item" do
      it "returns complete formatted hash" do
        result = formatter.to_h

        expect(result).to include(
          id: content_item.content_id,
          origin_id: content_item.origin_id,
          origin_source: content_item.origin_source,
          week: content_item.week,
          scheduled_day: content_item.scheduled_day,
          content_name: content_item.content_name,
          status: content_item.status,
          content_type: content_item.content_type,
          platform: content_item.platform,
          aspect_ratio: content_item.aspect_ratio,
          language: content_item.language,
          pilar: content_item.pilar,
          template: content_item.template,
          video_source: content_item.video_source,
          post_description: content_item.post_description,
          text_base: content_item.text_base
        )
      end

      it "formats dates correctly" do
        result = formatter.to_h

        expect(result[:creation_date]).to eq(content_item.creation_date.iso8601)
        expect(result[:publish_date]).to eq(content_item.publish_date.iso8601)
        expect(result[:publish_datetime_local]).to eq(content_item.publish_datetime_local.iso8601)
      end

      it "formats hashtags as array" do
        content_item.update(hashtags: "#tag1 #tag2 #tag3")
        result = formatter.to_h

        expect(result[:hashtags]).to eq([ "#tag1", "#tag2", "#tag3" ])
      end

      it "includes JSONB fields" do
        result = formatter.to_h

        expect(result[:subtitles]).to eq(content_item.subtitles)
        expect(result[:dubbing]).to eq(content_item.dubbing)
        expect(result[:accessibility]).to eq(content_item.accessibility)
        expect(result[:meta]).to eq(content_item.meta)
      end

      it "includes derived fields from meta" do
        result = formatter.to_h

        expect(result[:kpi_focus]).to eq("reach")
        expect(result[:success_criteria]).to eq("≥8% saves")
        expect(result[:compliance_check]).to eq("ok")
      end
    end

    context "with narration template" do
      let(:content_item) { create(:creas_content_item, :with_narration) }

      it "formats beats correctly" do
        result = formatter.to_h

        expect(result[:beats].length).to eq(7)
        expect(result[:beats].first).to include(
          idx: 1,
          image_prompt: "Image prompt 1",
          voiceover: "Voiceover 1"
        )
      end

      it "returns empty scenes array" do
        result = formatter.to_h
        expect(result[:scenes]).to eq([])
      end
    end

    context "with avatar template" do
      let(:content_item) { create(:creas_content_item, template: "solo_avatars") }

      it "formats scenes correctly" do
        result = formatter.to_h

        expect(result[:scenes].length).to eq(1)
        expect(result[:scenes].first).to include(
          id: 1,
          role: "Hook",
          type: "avatar",
          visual: "Close-up shot",
          on_screen_text: "Hook text",
          voiceover: "Hook voiceover",
          avatar_id: "avatar_123",
          voice_id: "voice_123",
          video_url: nil,
          video_prompt: nil
        )
      end

      it "returns empty beats array" do
        result = formatter.to_h
        expect(result[:beats]).to eq([])
      end
    end

    context "with external video" do
      let(:content_item) { create(:creas_content_item, :with_external_video) }

      it "includes external video information" do
        result = formatter.to_h

        expect(result[:external_videos]).to eq([ "https://example.com/video.mp4" ])
        expect(result[:video_prompts]).to eq([])
      end
    end

    context "with kling video" do
      let(:content_item) { create(:creas_content_item, :with_kling_video) }

      it "includes video prompts" do
        result = formatter.to_h

        expect(result[:video_prompts]).to eq([ "A beautiful sunset over mountains" ])
        expect(result[:external_videos]).to eq([])
      end
    end

    context "with broll suggestions" do
      let(:content_item) do
        create(:creas_content_item,
          assets: { "broll_suggestions" => [ "Scenic mountain views", "Close-up of hands typing" ] }
        )
      end

      it "includes broll suggestions" do
        result = formatter.to_h

        expect(result[:broll_suggestions]).to eq([ "Scenic mountain views", "Close-up of hands typing" ])
      end
    end

    context "with screen recording instructions" do
      let(:content_item) do
        create(:creas_content_item,
          assets: { "screen_recording_instructions" => "Record mobile app navigation" }
        )
      end

      it "includes screen recording instructions" do
        result = formatter.to_h

        expect(result[:screen_recording_instructions]).to eq("Record mobile app navigation")
      end
    end

    context "with nil dates" do
      let(:content_item) do
        item = create(:creas_content_item, publish_date: Date.current)
        # Manually set creation_date and publish_datetime_local to nil (bypassing validations)
        item.update_columns(creation_date: nil, publish_datetime_local: nil)
        item.reload
      end

      it "handles nil dates gracefully" do
        result = formatter.to_h

        expect(result[:creation_date]).to be_nil
        expect(result[:publish_date]).to eq(Date.current.iso8601)
        expect(result[:publish_datetime_local]).to be_nil
      end
    end

    context "with missing assets data" do
      let(:content_item) { create(:creas_content_item, assets: {}) }

      it "returns empty arrays for missing asset data" do
        result = formatter.to_h

        expect(result[:external_videos]).to eq([])
        expect(result[:video_prompts]).to eq([])
        expect(result[:broll_suggestions]).to eq([])
        expect(result[:screen_recording_instructions]).to eq("")
      end
    end

    context "with nil content item" do
      let(:formatter) { described_class.new(nil) }

      it "returns error hash" do
        result = formatter.to_h
        expect(result).to eq({ error: "Content item not found" })
      end
    end
  end
end
