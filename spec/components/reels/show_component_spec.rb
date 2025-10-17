require "rails_helper"

RSpec.describe Reels::ShowComponent, type: :component do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:reel) { create(:reel, brand: brand, user: user, title: "Test Reel", status: "completed") }

  before do
    # Stub the presenter's refresh method to avoid external API calls
    allow_any_instance_of(ReelShowPresenter).to receive(:refresh_video_url_if_needed)
  end

  it "renders the reel title" do
    render_inline(described_class.new(reel: reel, user: user))

    expect(page).to have_content("Test Reel")
  end

  it "renders the status badge component" do
    render_inline(described_class.new(reel: reel, user: user))

    expect(page).to have_css(".status-badge")
  end

  context "when reel has a video" do
    let(:reel) do
      create(:reel,
        brand: brand,
        user: user,
        status: "completed",
        video_url: "https://example.com/video.mp4"
      )
    end

    it "renders the video element" do
      render_inline(described_class.new(reel: reel, user: user))

      expect(page).to have_css("video[controls]")
      expect(page).to have_css("source[src='https://example.com/video.mp4']")
    end
  end

  context "when reel is processing" do
    let(:reel) { create(:reel, brand: brand, user: user, status: "processing") }

    it "shows processing indicator" do
      render_inline(described_class.new(reel: reel, user: user))

      expect(page).to have_content("Your video is being generated with HeyGen")
      expect(page).to have_css(".animate-spin")
    end
  end

  context "when reel has failed" do
    let(:reel) { create(:reel, brand: brand, user: user, status: "failed") }

    it "shows error message" do
      render_inline(described_class.new(reel: reel, user: user))

      expect(page).to have_content("There was an error generating your video")
      expect(page).to have_css(".bg-red-50")
    end
  end

  it "renders reel details section" do
    render_inline(described_class.new(reel: reel, user: user))

    expect(page).to have_content(I18n.t("reels.show.reel_details"))
    expect(page).to have_content(I18n.t("reels.show.template"))
    expect(page).to have_content(I18n.t("reels.show.created"))
  end
end
