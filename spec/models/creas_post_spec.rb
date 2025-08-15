require 'rails_helper'

RSpec.describe CreasPost, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:creas_strategy_plan) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content_name) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:creation_date) }
    it { should validate_presence_of(:publish_date) }
    it { should validate_presence_of(:content_type) }
    it { should validate_presence_of(:platform) }
    it { should validate_presence_of(:pilar) }
    it { should validate_presence_of(:template) }
    it { should validate_presence_of(:video_source) }
    it { should validate_presence_of(:post_description) }
    it { should validate_presence_of(:text_base) }
    it { should validate_presence_of(:hashtags) }
  end

  describe 'JSONB defaults' do
    let(:creas_post) { create(:creas_post) }

    it 'has default empty hashes for subtitles' do
      expect(creas_post.subtitles).to be_a(Hash)
    end

    it 'has default empty hashes for dubbing' do
      expect(creas_post.dubbing).to be_a(Hash)
    end

    it 'has default empty hashes for shotplan' do
      expect(creas_post.shotplan).to be_a(Hash)
    end

    it 'has default empty hashes for assets' do
      expect(creas_post.assets).to be_a(Hash)
    end

    it 'has default empty hashes for accessibility' do
      expect(creas_post.accessibility).to be_a(Hash)
    end

    it 'has default empty hashes for raw_payload' do
      expect(creas_post.raw_payload).to be_a(Hash)
    end

    it 'has default empty hashes for meta' do
      expect(creas_post.meta).to be_a(Hash)
    end
  end

  describe 'default values' do
    it 'has default content_type of Video' do
      creas_post = build(:creas_post, content_type: '')
      creas_post.save(validate: false)
      expect(creas_post.content_type).to eq('Video')
    end

    it 'has default platform of Instagram Reels' do
      creas_post = build(:creas_post, platform: '')
      creas_post.save(validate: false)
      expect(creas_post.platform).to eq('Instagram Reels')
    end

    it 'has default aspect_ratio of 9:16' do
      creas_post = build(:creas_post, aspect_ratio: nil)
      creas_post.save(validate: false)
      expect(creas_post.aspect_ratio).to eq('9:16')
    end
  end
end
