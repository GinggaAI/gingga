require 'rails_helper'

RSpec.describe CreasContentItem, type: :model do
  subject { create(:creas_content_item) }

  describe "associations" do
    it { is_expected.to belong_to(:creas_strategy_plan) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:brand) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:content_id) }
    it { is_expected.to validate_presence_of(:content_name) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:creation_date) }
    it { is_expected.to validate_presence_of(:publish_date) }
    it { is_expected.to validate_presence_of(:content_type) }
    it { is_expected.to validate_presence_of(:platform) }
    it { is_expected.to validate_presence_of(:week) }
    it { is_expected.to validate_presence_of(:pilar) }
    it { is_expected.to validate_presence_of(:template) }
    it { is_expected.to validate_presence_of(:video_source) }

    it { is_expected.to validate_uniqueness_of(:content_id) }

    describe "status validation" do
      it "allows valid status values" do
        %w[in_production ready_for_review approved].each do |status|
          content_item = build(:creas_content_item, status: status)
          expect(content_item).to be_valid
        end
      end

      it "rejects invalid status values" do
        content_item = build(:creas_content_item, status: "invalid_status")
        expect(content_item).not_to be_valid
        expect(content_item.errors[:status]).to include("invalid_status is not a valid status")
      end
    end

    describe "template validation" do
      it "allows valid template values" do
        %w[only_avatars avatar_and_video narration_over_7_images remix one_to_three_videos].each do |template|
          content_item = build(:creas_content_item, template: template)
          expect(content_item).to be_valid
        end
      end

      it "rejects invalid template values" do
        content_item = build(:creas_content_item, template: "invalid_template")
        expect(content_item).not_to be_valid
        expect(content_item.errors[:template]).to include("invalid_template is not a valid template")
      end
    end

    describe "video_source validation" do
      it "allows valid video_source values" do
        %w[none external kling].each do |video_source|
          content_item = build(:creas_content_item, video_source: video_source)
          expect(content_item).to be_valid
        end
      end

      it "rejects invalid video_source values" do
        content_item = build(:creas_content_item, video_source: "invalid_source")
        expect(content_item).not_to be_valid
        expect(content_item.errors[:video_source]).to include("invalid_source is not a valid video source")
      end
    end

    describe "pilar validation" do
      it "allows valid pilar values" do
        %w[C R E A S].each do |pilar|
          content_item = build(:creas_content_item, pilar: pilar)
          expect(content_item).to be_valid
        end
      end

      it "rejects invalid pilar values" do
        content_item = build(:creas_content_item, pilar: "X")
        expect(content_item).not_to be_valid
        expect(content_item.errors[:pilar]).to include("X is not a valid pilar")
      end
    end

    describe "day_of_the_week validation" do
      it "allows valid day_of_the_week values" do
        %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday].each do |day|
          content_item = build(:creas_content_item, day_of_the_week: day)
          expect(content_item).to be_valid, "Expected '#{day}' to be valid"
        end
      end

      it "rejects invalid day_of_the_week values" do
        content_item = build(:creas_content_item, day_of_the_week: "Funday")
        expect(content_item).not_to be_valid
        expect(content_item.errors[:day_of_the_week]).to include("Funday is not a valid day of the week")
      end

      it "allows blank day_of_the_week" do
        content_item = build(:creas_content_item, day_of_the_week: nil)
        expect(content_item).to be_valid

        content_item = build(:creas_content_item, day_of_the_week: "")
        expect(content_item).to be_valid
      end
    end

    describe "hashtags validation" do
      it "allows valid hashtag formats" do
        valid_hashtags = [
          "#tag1 #tag2 #tag3",
          "#single",
          "#tag1   #tag2", # extra spaces
          "", # blank is allowed
          nil # nil is allowed
        ]

        valid_hashtags.each do |hashtags|
          content_item = build(:creas_content_item, hashtags: hashtags)
          expect(content_item).to be_valid, "Expected '#{hashtags}' to be valid"
        end
      end

      it "rejects invalid hashtag formats" do
        invalid_hashtags = [
          "no hash tags",
          "#tag1\n#tag2", # newlines not allowed
          "tag1 tag2", # missing # symbols
          "#tag1 notag #tag2" # mixed format
        ]

        invalid_hashtags.each do |hashtags|
          content_item = build(:creas_content_item, hashtags: hashtags)
          expect(content_item).not_to be_valid, "Expected '#{hashtags}' to be invalid"
        end
      end
    end
  end

  describe "scopes" do
    let(:strategy_plan_1) { create(:creas_strategy_plan) }
    let(:strategy_plan_2) { create(:creas_strategy_plan) }
    let!(:week1_item) { create(:creas_content_item, week: 1, creas_strategy_plan: strategy_plan_1) }
    let!(:week2_item) { create(:creas_content_item, week: 2, creas_strategy_plan: strategy_plan_2) }
    let!(:in_production_item) { create(:creas_content_item, status: "in_production", week: 3) }
    let!(:ready_item) { create(:creas_content_item, :ready_for_review, week: 3) }
    let!(:approved_item) { create(:creas_content_item, :approved, week: 4) }

    describe ".by_week" do
      it "returns items for specified week" do
        expect(CreasContentItem.by_week(1)).to contain_exactly(week1_item)
        expect(CreasContentItem.by_week(2)).to contain_exactly(week2_item)
      end
    end

    describe ".by_status" do
      it "returns items with specified status" do
        expect(CreasContentItem.by_status("in_production")).to include(in_production_item)
        expect(CreasContentItem.by_status("ready_for_review")).to contain_exactly(ready_item)
      end
    end

    describe ".ready_to_publish" do
      it "returns items that are ready for review or approved" do
        result = CreasContentItem.ready_to_publish
        expect(result).to include(ready_item, approved_item)
        expect(result).not_to include(in_production_item)
      end
    end

    describe ".by_day_of_week" do
      let!(:monday_item) { create(:creas_content_item, day_of_the_week: "Monday") }
      let!(:tuesday_item) { create(:creas_content_item, day_of_the_week: "Tuesday") }
      let!(:wednesday_item) { create(:creas_content_item, day_of_the_week: "Wednesday") }

      it "returns items for specified day of week" do
        expect(CreasContentItem.by_day_of_week("Monday")).to contain_exactly(monday_item)
        expect(CreasContentItem.by_day_of_week("Tuesday")).to contain_exactly(tuesday_item)
        expect(CreasContentItem.by_day_of_week("Wednesday")).to contain_exactly(wednesday_item)
      end
    end

    describe ".for_month" do
      let(:plan_jan) { create(:creas_strategy_plan, month: "2025-01") }
      let(:plan_feb) { create(:creas_strategy_plan, month: "2025-02") }
      let!(:jan_item) { create(:creas_content_item, creas_strategy_plan: plan_jan) }
      let!(:feb_item) { create(:creas_content_item, creas_strategy_plan: plan_feb) }

      it "returns items for specified month" do
        expect(CreasContentItem.for_month("2025-01")).to contain_exactly(jan_item)
        expect(CreasContentItem.for_month("2025-02")).to contain_exactly(feb_item)
      end
    end
  end

  describe "instance methods" do
    describe "#formatted_hashtags" do
      it "returns array of hashtags" do
        item = create(:creas_content_item, hashtags: "#tag1 #tag2 #tag3")
        expect(item.formatted_hashtags).to eq([ "#tag1", "#tag2", "#tag3" ])
      end

      it "handles extra spaces" do
        item = create(:creas_content_item, hashtags: "#tag1   #tag2   #tag3")
        expect(item.formatted_hashtags).to eq([ "#tag1", "#tag2", "#tag3" ])
      end

      it "returns empty array for blank hashtags" do
        item = create(:creas_content_item, hashtags: "")
        expect(item.formatted_hashtags).to eq([])
      end
    end

    describe "#scenes" do
      it "returns scenes from shotplan" do
        item = create(:creas_content_item)
        expect(item.scenes).to be_an(Array)
        expect(item.scenes.first).to include("id" => 1, "role" => "Hook")
      end

      it "returns empty array when shotplan has no scenes" do
        item = create(:creas_content_item, shotplan: {})
        expect(item.scenes).to eq([])
      end
    end

    describe "#beats" do
      it "returns empty array for non-narration template" do
        item = create(:creas_content_item, template: "only_avatars")
        expect(item.beats).to eq([])
      end

      it "returns beats for narration template" do
        item = create(:creas_content_item, :with_narration)
        expect(item.beats.length).to eq(7)
        expect(item.beats.first).to include("idx" => 1, "image_prompt" => "Image prompt 1")
      end
    end

    describe "#external_videos" do
      it "returns external_video_url as array when present" do
        item = create(:creas_content_item, assets: { "external_video_url" => "https://example.com/video.mp4" })
        expect(item.external_videos).to eq([ "https://example.com/video.mp4" ])
      end

      it "returns video_urls when external_video_url is not present" do
        item = create(:creas_content_item, assets: { "video_urls" => [ "https://example.com/video1.mp4", "https://example.com/video2.mp4" ] })
        expect(item.external_videos).to eq([ "https://example.com/video1.mp4", "https://example.com/video2.mp4" ])
      end

      it "returns empty array when no video urls" do
        item = create(:creas_content_item, assets: {})
        expect(item.external_videos).to eq([])
      end
    end
  end
end
