require 'rails_helper'

RSpec.describe Creas::ContentItemInitializerService do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user, content_language: 'en', timezone: 'Europe/Madrid') }
  let(:strategy_plan) { create(:creas_strategy_plan, user: user, brand: brand) }
  let(:service) { described_class.new(strategy_plan: strategy_plan) }

  describe '#initialize' do
    it 'sets the strategy plan, user, and brand' do
      expect(service.instance_variable_get(:@plan)).to eq(strategy_plan)
      expect(service.instance_variable_get(:@user)).to eq(user)
      expect(service.instance_variable_get(:@brand)).to eq(brand)
    end
  end

  describe '#call' do
    context 'when content_distribution is empty' do
      let(:strategy_plan) { create(:creas_strategy_plan, user: user, brand: brand, content_distribution: {}) }

      it 'returns an empty array' do
        expect(service.call).to eq([])
      end
    end

    context 'when content_distribution has valid data' do
      let(:content_distribution) do
        {
          'C' => {
            'ideas' => [
              {
                'id' => '202508-gingga-C-w1-i1',
                'title' => 'Test Content',
                'description' => 'Test description',
                'platform' => 'Instagram',
                'hook' => 'Amazing hook',
                'cta' => 'Follow us!',
                'kpi_focus' => 'engagement',
                'success_criteria' => '≥10% saves',
                'recommended_template' => 'solo_avatars',
                'video_source' => 'kling',
                'visual_notes' => 'Cool visuals',
                'repurpose_to' => [ 'TikTok' ],
                'language_variants' => [ 'es' ],
                'beats_outline' => [ 'Beat 1', 'Beat 2' ],
                'assets_hints' => {
                  'video_prompts' => [ 'Prompt 1', 'Prompt 2' ],
                  'broll_suggestions' => [ 'Broll 1' ],
                  'external_video_url' => 'https://example.com/video.mp4',
                  'external_video_notes' => 'Video notes'
                }
              }
            ]
          },
          'R' => {
            'ideas' => [
              {
                'id' => '202508-gingga-R-w2-i1',
                'title' => 'Second Content',
                'platform' => 'TikTok'
              }
            ]
          }
        }
      end
      let(:weekly_plan) do
        [
          {
            'ideas' => [
              { 'id' => '202508-gingga-C-w1-i1' }
            ]
          },
          {
            'ideas' => [
              { 'id' => '202508-gingga-R-w2-i1' }
            ]
          }
        ]
      end
      let(:strategy_plan) do
        create(:creas_strategy_plan,
               user: user,
               brand: brand,
               content_distribution: content_distribution,
               weekly_plan: weekly_plan)
      end

      it 'creates content items in a transaction' do
        expect(CreasContentItem).to receive(:transaction).and_yield
        service.call
      end

      it 'creates content items for each idea' do
        expect { service.call }.to change { CreasContentItem.count }.by(2)
      end

      it 'returns the created content items' do
        result = service.call
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.all? { |item| item.is_a?(CreasContentItem) }).to be true
      end

      it 'sets correct attributes on content items' do
        items = service.call

        first_item = items.find { |item| item.content_id == '202508-gingga-C-w1-i1' }
        expect(first_item).to have_attributes(
          content_id: '202508-gingga-C-w1-i1',
          origin_id: '202508-gingga-C-w1-i1',
          origin_source: 'content_distribution',
          week: 1,
          week_index: 0,
          content_name: 'Test Content',
          status: 'draft',
          content_type: 'reel',
          platform: 'instagram',
          aspect_ratio: '9:16',
          language: 'en',
          pilar: 'C',
          template: 'solo_avatars',
          video_source: 'kling',
          post_description: 'Test description',
          timezone: 'Europe/Madrid',
          user: user,
          brand: brand,
          creas_strategy_plan: strategy_plan
        )

        # Verify day_of_the_week is assigned
        expect(first_item.day_of_the_week).to be_present
        expect(%w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]).to include(first_item.day_of_the_week)

        expect(first_item.text_base).to eq("Amazing hook\n\nTest description\n\nFollow us!")
        expect(first_item.shotplan['beats']).to eq([
          { 'beat_number' => 1, 'description' => 'Beat 1', 'duration' => '3-5s' },
          { 'beat_number' => 2, 'description' => 'Beat 2', 'duration' => '3-5s' }
        ])
        expect(first_item.assets).to eq({
          'video_prompts' => [ 'Prompt 1', 'Prompt 2' ],
          'broll_suggestions' => [ 'Broll 1' ],
          'external_video_url' => 'https://example.com/video.mp4',
          'external_video_notes' => 'Video notes'
        })
        expect(first_item.meta).to eq({
          'kpi_focus' => 'engagement',
          'success_criteria' => '≥10% saves',
          'compliance_check' => 'pending',
          'visual_notes' => 'Cool visuals',
          'hook' => 'Amazing hook',
          'cta' => 'Follow us!',
          'repurpose_to' => [ 'TikTok' ],
          'language_variants' => [ 'es' ]
        })
      end

      it 'handles pilars without ideas' do
        content_distribution_with_empty_pilar = content_distribution.merge('E' => {})
        strategy_plan.update!(content_distribution: content_distribution_with_empty_pilar)

        expect { service.call }.to change { CreasContentItem.count }.by(2)
      end

      it 'handles pilars with ideas key but no ideas array' do
        content_distribution_with_nil_ideas = content_distribution.merge('E' => { 'ideas' => nil })
        strategy_plan.update!(content_distribution: content_distribution_with_nil_ideas)

        expect { service.call }.to change { CreasContentItem.count }.by(2)
      end
    end

    context 'when content item already exists' do
      let(:content_distribution) do
        {
          'C' => {
            'ideas' => [
              {
                'id' => 'existing-content-id',
                'title' => 'Updated Content',
                'platform' => 'Instagram'
              }
            ]
          }
        }
      end
      let(:strategy_plan) do
        create(:creas_strategy_plan, user: user, brand: brand, content_distribution: content_distribution)
      end

      before do
        create(:creas_content_item,
               content_id: 'existing-content-id',
               content_name: 'Original Content',
               user: user,
               brand: brand,
               creas_strategy_plan: strategy_plan)
      end

      it 'updates existing content item instead of creating new one' do
        expect { service.call }.not_to change { CreasContentItem.count }

        item = CreasContentItem.find_by(content_id: 'existing-content-id')
        expect(item.content_name).to eq('Updated Content')
      end
    end

    context 'when save fails' do
      let(:content_distribution) do
        {
          'C' => {
            'ideas' => [
              { 'id' => 'test-id', 'title' => 'Test Content', 'platform' => 'Instagram' }
            ]
          }
        }
      end
      let(:strategy_plan) do
        create(:creas_strategy_plan, user: user, brand: brand, content_distribution: content_distribution)
      end

      before do
        allow_any_instance_of(CreasContentItem).to receive(:save!).and_raise(
          ActiveRecord::RecordInvalid.new(CreasContentItem.new)
        )
        allow(Rails.logger).to receive(:warn)
      end

      it 'logs the error and continues' do
        result = service.call

        expect(Rails.logger).to have_received(:warn).with(/Failed to create CreasContentItem/)
        expect(Rails.logger).to have_received(:warn).with(/Attributes:/)
        expect(result).to be_an(Array)
      end
    end
  end

  describe '#extract_week_from_idea' do
    let(:service) { described_class.new(strategy_plan: strategy_plan) }

    context 'when idea is found in weekly_plan' do
      let(:weekly_plan) do
        [
          { 'ideas' => [ { 'id' => 'idea-1' } ] },
          { 'ideas' => [ { 'id' => 'idea-2' } ] },
          { 'ideas' => [ { 'id' => 'idea-3' } ] }
        ]
      end
      let(:strategy_plan) do
        create(:creas_strategy_plan, user: user, brand: brand, weekly_plan: weekly_plan)
      end

      it 'returns the correct week number' do
        idea = { 'id' => 'idea-2' }
        week = service.send(:extract_week_from_idea, idea)
        expect(week).to eq(2)
      end
    end

    context 'when idea has week pattern in ID' do
      let(:strategy_plan) { create(:creas_strategy_plan, user: user, brand: brand, weekly_plan: []) }

      it 'extracts week from ID pattern' do
        idea = { 'id' => '202508-gingga-A-w3-i1' }
        week = service.send(:extract_week_from_idea, idea)
        expect(week).to eq(3)
      end
    end

    context 'when no week can be determined' do
      let(:strategy_plan) { create(:creas_strategy_plan, user: user, brand: brand, weekly_plan: []) }

      it 'defaults to week 1' do
        idea = { 'id' => 'no-week-pattern' }
        week = service.send(:extract_week_from_idea, idea)
        expect(week).to eq(1)
      end
    end
  end

  describe '#determine_content_type' do
    let(:service) { described_class.new(strategy_plan: strategy_plan) }

    it 'returns reel for Instagram' do
      idea = { 'platform' => 'Instagram' }
      expect(service.send(:determine_content_type, idea)).to eq('reel')
    end

    it 'returns video for TikTok' do
      idea = { 'platform' => 'TikTok' }
      expect(service.send(:determine_content_type, idea)).to eq('video')
    end

    it 'returns video for YouTube' do
      idea = { 'platform' => 'YouTube' }
      expect(service.send(:determine_content_type, idea)).to eq('video')
    end

    it 'returns post for unknown platform' do
      idea = { 'platform' => 'Unknown' }
      expect(service.send(:determine_content_type, idea)).to eq('post')
    end

    it 'handles nil platform' do
      idea = { 'platform' => nil }
      expect(service.send(:determine_content_type, idea)).to eq('post')
    end
  end

  describe '#determine_aspect_ratio' do
    let(:service) { described_class.new(strategy_plan: strategy_plan) }

    it 'returns 9:16 for Instagram' do
      expect(service.send(:determine_aspect_ratio, 'Instagram')).to eq('9:16')
    end

    it 'returns 9:16 for TikTok' do
      expect(service.send(:determine_aspect_ratio, 'TikTok')).to eq('9:16')
    end

    it 'returns 16:9 for YouTube' do
      expect(service.send(:determine_aspect_ratio, 'YouTube')).to eq('16:9')
    end

    it 'returns 1:1 for unknown platform' do
      expect(service.send(:determine_aspect_ratio, 'Unknown')).to eq('1:1')
    end

    it 'handles nil platform' do
      expect(service.send(:determine_aspect_ratio, nil)).to eq('1:1')
    end
  end

  describe '#build_text_base' do
    let(:service) { described_class.new(strategy_plan: strategy_plan) }

    it 'combines hook, description, and cta with double newlines' do
      idea = {
        'hook' => 'Great hook',
        'description' => 'Amazing description',
        'cta' => 'Call to action'
      }

      result = service.send(:build_text_base, idea)
      expect(result).to eq("Great hook\n\nAmazing description\n\nCall to action")
    end

    it 'handles missing parts' do
      idea = { 'hook' => 'Hook only' }
      result = service.send(:build_text_base, idea)
      expect(result).to eq('Hook only')
    end

    it 'handles empty strings' do
      idea = {
        'hook' => 'Hook',
        'description' => '',
        'cta' => 'CTA'
      }
      result = service.send(:build_text_base, idea)
      expect(result).to eq("Hook\n\nCTA")
    end

    it 'returns empty string when all parts are missing' do
      idea = {}
      result = service.send(:build_text_base, idea)
      expect(result).to eq('')
    end
  end

  describe '#build_shotplan' do
    let(:service) { described_class.new(strategy_plan: strategy_plan) }

    it 'builds beats from beats_outline' do
      idea = { 'beats_outline' => [ 'First beat', 'Second beat' ] }

      result = service.send(:build_shotplan, idea)
      expect(result['beats']).to eq([
        { 'beat_number' => 1, 'description' => 'First beat', 'duration' => '3-5s' },
        { 'beat_number' => 2, 'description' => 'Second beat', 'duration' => '3-5s' }
      ])
    end

    it 'builds scenes from assets_hints' do
      idea = {
        'assets_hints' => {
          'video_prompts' => [ 'Prompt 1', 'Prompt 2' ],
          'broll_suggestions' => [ 'Broll 1', 'Broll 2' ]
        }
      }

      result = service.send(:build_shotplan, idea)
      expect(result['scenes']).to eq([
        {
          'scene_number' => 1,
          'description' => 'Prompt 1',
          'visual_elements' => [ 'Broll 1', 'Broll 2' ]
        },
        {
          'scene_number' => 2,
          'description' => 'Prompt 2',
          'visual_elements' => [ 'Broll 1', 'Broll 2' ]
        }
      ])
    end

    it 'returns empty shotplan when no data provided' do
      idea = {}
      result = service.send(:build_shotplan, idea)
      expect(result).to eq({})
    end
  end

  describe '#build_assets' do
    let(:service) { described_class.new(strategy_plan: strategy_plan) }

    it 'builds assets from assets_hints' do
      idea = {
        'assets_hints' => {
          'video_prompts' => [ 'Prompt 1' ],
          'broll_suggestions' => [ 'Broll 1' ],
          'external_video_url' => 'https://example.com/video.mp4',
          'external_video_notes' => 'Video notes'
        }
      }

      result = service.send(:build_assets, idea)
      expect(result).to eq({
        'video_prompts' => [ 'Prompt 1' ],
        'broll_suggestions' => [ 'Broll 1' ],
        'external_video_url' => 'https://example.com/video.mp4',
        'external_video_notes' => 'Video notes'
      })
    end

    it 'handles missing assets_hints' do
      idea = {}
      result = service.send(:build_assets, idea)
      expect(result).to eq({})
    end

    it 'handles partial assets_hints' do
      idea = {
        'assets_hints' => {
          'video_prompts' => [ 'Prompt 1' ]
        }
      }

      result = service.send(:build_assets, idea)
      expect(result).to eq({
        'video_prompts' => [ 'Prompt 1' ],
        'broll_suggestions' => []
      })
    end
  end

  describe '#build_meta' do
    let(:service) { described_class.new(strategy_plan: strategy_plan) }

    it 'builds meta with all provided fields' do
      idea = {
        'kpi_focus' => 'engagement',
        'success_criteria' => '≥10% saves',
        'visual_notes' => 'Visual notes',
        'hook' => 'Hook text',
        'cta' => 'CTA text',
        'repurpose_to' => [ 'TikTok', 'YouTube' ],
        'language_variants' => [ 'es', 'fr' ]
      }

      result = service.send(:build_meta, idea)
      expect(result).to eq({
        'kpi_focus' => 'engagement',
        'success_criteria' => '≥10% saves',
        'compliance_check' => 'pending',
        'visual_notes' => 'Visual notes',
        'hook' => 'Hook text',
        'cta' => 'CTA text',
        'repurpose_to' => [ 'TikTok', 'YouTube' ],
        'language_variants' => [ 'es', 'fr' ]
      })
    end

    it 'handles missing fields with defaults' do
      idea = { 'kpi_focus' => 'reach' }

      result = service.send(:build_meta, idea)
      expect(result).to eq({
        'kpi_focus' => 'reach',
        'success_criteria' => nil,
        'compliance_check' => 'pending',
        'visual_notes' => nil,
        'hook' => nil,
        'cta' => nil,
        'repurpose_to' => [],
        'language_variants' => []
      })
    end
  end

  context 'edge cases' do
    context 'when brand has no timezone' do
      let(:brand) { create(:brand, user: user, timezone: nil) }
      let(:content_distribution) do
        {
          'C' => {
            'ideas' => [
              { 'id' => 'test-id', 'title' => 'Test', 'platform' => 'Instagram' }
            ]
          }
        }
      end
      let(:strategy_plan) do
        create(:creas_strategy_plan, user: user, brand: brand, content_distribution: content_distribution)
      end

      it 'defaults to UTC timezone' do
        items = service.call
        expect(items.first.timezone).to eq('UTC')
      end
    end

    context 'when brand has no content_language' do
      let(:brand) { create(:brand, user: user, content_language: nil) }
      let(:content_distribution) do
        {
          'C' => {
            'ideas' => [
              { 'id' => 'test-id', 'title' => 'Test', 'platform' => 'Instagram' }
            ]
          }
        }
      end
      let(:strategy_plan) do
        create(:creas_strategy_plan, user: user, brand: brand, content_distribution: content_distribution)
      end

      it 'defaults to en language' do
        items = service.call
        expect(items.first.language).to eq('en')
      end
    end

    context 'when idea has missing title' do
      let(:content_distribution) do
        {
          'C' => {
            'ideas' => [
              { 'id' => 'test-id', 'platform' => 'Instagram' }
            ]
          }
        }
      end
      let(:strategy_plan) do
        create(:creas_strategy_plan, user: user, brand: brand, content_distribution: content_distribution)
      end

      it 'generates default content name' do
        items = service.call
        expect(items.first.content_name).to eq('Content test-id')
      end
    end
  end
end
