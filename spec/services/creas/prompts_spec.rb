require 'rails_helper'

RSpec.describe Creas::Prompts do
  describe 'module constants' do
    it 'defines NOCTUA_VERSION' do
      expect(Creas::Prompts::NOCTUA_VERSION).to eq('noctua-2025-08-12')
    end

    it 'defines VOXA_VERSION' do
      expect(Creas::Prompts::VOXA_VERSION).to eq('voxa-2025-08-19')
    end
  end

  describe '.noctua_system' do
    subject { described_class.noctua_system }

    it 'returns a string prompt' do
      expect(subject).to be_a(String)
      expect(subject.length).to be > 100
    end

    it 'contains key system prompt elements' do
      expect(subject).to include('You are CREAS Strategist (Noctua)')
      expect(subject).to include('5 pillars')
      expect(subject).to include('C Growth • R Retention • E Scalability • A Activation • S Satisfaction')
    end

    it 'includes mandatory brief requirements' do
      expect(subject).to include('MANDATORY BRIEF')
      expect(subject).to include('Brand name')
      expect(subject).to include('Sector/industry')
      expect(subject).to include('Audience profile')
      expect(subject).to include('Languages')
      expect(subject).to include('Value proposition')
    end

    it 'includes strategy rules' do
      expect(subject).to include('STRATEGY RULES')
      expect(subject).to include('Distribute weekly posting volume')
      expect(subject).to include('primary pillar = 40–50%')
      expect(subject).to include('other four pillars = 50–60%')
    end

    it 'defines JSON output contract' do
      expect(subject).to include('OUTPUT CONTRACT')
      expect(subject).to include('single JSON object')
      expect(subject).to include('brand_name')
      expect(subject).to include('strategy_name')
      expect(subject).to include('content_distribution')
      expect(subject).to include('weekly_plan')
    end

    it 'includes pillar object structure' do
      expect(subject).to include('PILLAR_OBJ')
      expect(subject).to include('goal')
      expect(subject).to include('formats')
      expect(subject).to include('ideas')
    end

    it 'defines idea object structure' do
      expect(subject).to include('IDEA_OBJ')
      expect(subject).to include('title')
      expect(subject).to include('hook')
      expect(subject).to include('description')
      expect(subject).to include('platform')
      expect(subject).to include('recommended_template')
    end

    it 'includes allowed values constraints' do
      expect(subject).to include('ALLOWED VALUES')
      expect(subject).to include('awareness | engagement | sales | community')
      expect(subject).to include('solo_avatars | avatar_and_video')
      expect(subject).to include('reach | saves | comments | CTR | DM')
    end

    it 'includes validation rules' do
      expect(subject).to include('VALIDATION')
      expect(subject).to include('brief complete')
      expect(subject).to include('all IDs valid/unique')
      expect(subject).to include('respect brand_guardrails')
    end

    it 'includes ID generation rules' do
      expect(subject).to include('ID RULES')
      expect(subject).to include('YYYYMM-<brand_slug>-<PILLAR>-w<week>-i<idx>')
      expect(subject).to include('YYYYMM-<brand_slug>-w<week>-i<idx>-<PILLAR>')
    end

    it 'is properly formatted as heredoc' do
      # Should not have extra indentation at start
      lines = subject.split("\n")
      expect(lines.first).not_to start_with('      ')
      # Should contain structured sections
      expect(lines.any? { |line| line.start_with?('MANDATORY BRIEF') }).to be true
    end
  end

  describe '.noctua_user' do
    let(:brief_hash) do
      {
        brand_name: 'Test Brand',
        industry: 'Technology',
        audience_profile: 'Tech professionals',
        content_language: 'en-US',
        target_region: 'North America',
        value_proposition: 'Innovation in tech',
        main_offer: 'SaaS product',
        mission: 'Empower developers',
        tone_style: 'Professional yet approachable',
        priority_platforms: [ 'Instagram', 'LinkedIn' ],
        monthly_themes: [ 'Innovation', 'Community' ],
        objective_of_the_month: 'awareness',
        frequency_per_week: 4,
        resources_override: { budget: 1000 }
      }
    end

    subject { described_class.noctua_user(brief_hash) }

    it 'returns a formatted user prompt' do
      expect(subject).to be_a(String)
      expect(subject.length).to be > 50
    end

    it 'includes the MANDATORY BRIEF header' do
      expect(subject).to include('# MANDATORY BRIEF')
    end

    it 'contains the JSON representation of the brief' do
      expect(subject).to include(brief_hash.to_json)
    end

    it 'includes all key brief elements in JSON' do
      expect(subject).to include('"brand_name":"Test Brand"')
      expect(subject).to include('"industry":"Technology"')
      expect(subject).to include('"objective_of_the_month":"awareness"')
      expect(subject).to include('"frequency_per_week":4')
    end

    it 'handles empty brief hash' do
      empty_brief = {}
      result = described_class.noctua_user(empty_brief)
      expect(result).to include('# MANDATORY BRIEF')
      expect(result).to include('{}')
    end

    it 'handles nil values in brief' do
      brief_with_nils = brief_hash.merge(brand_name: nil, industry: nil)
      result = described_class.noctua_user(brief_with_nils)
      expect(result).to include('null')
      expect(result).to be_a(String)
    end
  end

  describe '.voxa_system' do
    let(:strategy_plan_data) { { brand_name: "Test Brand" } }
    subject { described_class.voxa_system(strategy_plan_data: strategy_plan_data) }

    it 'returns a comprehensive system prompt' do
      expect(subject).to be_a(String)
      expect(subject.length).to be > 1000
    end

    it 'identifies as CREAS Creator (Voxa)' do
      expect(subject).to include('You are CREAS Creator (Voxa)')
      expect(subject).to include('Convert normalized strategy data from StrategyPlanFormatter')
    end

    it 'defines scope and constraints' do
      expect(subject).to include('Scope')
      expect(subject).to include('Output only Reels')
      expect(subject).to include('vertical 9:16')
      expect(subject).to include('Instagram Reels')
    end

    it 'specifies input requirements' do
      expect(subject).to include('Input')
      expect(subject).to include('strategy_plan_data: Normalized output from StrategyPlanFormatter')
      expect(subject).to include('brand_context: Brand information')
    end

    it 'defines output contract structure' do
      expect(subject).to include('Output contract')
      expect(subject).to include('brand_name')
      expect(subject).to include('items')
      expect(subject).to include('ITEM_OBJ')
    end

    it 'includes comprehensive ITEM_OBJ structure' do
      expect(subject).to include('ITEM_OBJ')
      expect(subject).to include('origin_id')
      expect(subject).to include('content_name')
      expect(subject).to include('publish_datetime_local')
      expect(subject).to include('shotplan')
      expect(subject).to include('assets')
      expect(subject).to include('accessibility')
    end

    it 'defines template rules' do
      expect(subject).to include('Template rules')
      expect(subject).to include('solo_avatars')
      expect(subject).to include('avatar_and_video')
      expect(subject).to include('narration_over_7_images')
      expect(subject).to include('remix')
      expect(subject).to include('one_to_three_videos')
    end

    it 'includes creative guidelines' do
      expect(subject).to include('Creative rules')
      expect(subject).to include('Hook (0–3s)')
      expect(subject).to include('Development: tangible value')
      expect(subject).to include('Close: explicit CTA')
    end

    it 'specifies scheduling rules' do
      expect(subject).to include('Scheduling')
      expect(subject).to include('creation_date = today')
      expect(subject).to include('publish_date = today + 3..5 days')
    end

    it 'includes validation requirements' do
      expect(subject).to include('Validation')
      expect(subject).to include('Root keys present')
      expect(subject).to include('narration_over_7_images → exactly 7 beats')
      expect(subject).to include('hashtags = 3–5 items')
    end

    it 'defines behavioral guidelines' do
      expect(subject).to include('Behavior')
      expect(subject).to include('Be faithful to GPT-1')
      expect(subject).to include('immediately producible')
    end
  end

  describe '.voxa_user' do
    let(:strategy_plan_data) do
      {
        brand_name: 'Test Brand',
        strategy_name: 'August Strategy 2025',
        month: '2025-08',
        objective_of_the_month: 'awareness',
        frequency_per_week: 4,
        content_distribution: {
          'C' => {
            goal: 'Growth',
            formats: [ 'Video', 'Carousel' ],
            ideas: [
              {
                id: '202508-test-brand-C-w1-i1',
                title: 'Growth Strategy Tips',
                hook: 'Want to grow your business?',
                platform: 'Instagram'
              }
            ]
          }
        },
        weekly_plan: [
          {
            week: 1,
            publish_cadence: 4,
            ideas: [
              {
                id: '202508-test-brand-w1-i1-C',
                title: 'Week 1 Growth Content',
                hook: 'This week we focus on growth',
                pilar: 'C'
              }
            ]
          }
        ]
      }
    end

    let(:brand_context) do
      {
        "brand" => {
          "industry" => "Technology",
          "value_proposition" => "Innovation in tech",
          "priority_platforms" => [ "Instagram", "TikTok" ]
        }
      }
    end

    subject { described_class.voxa_user(strategy_plan_data: strategy_plan_data, brand_context: brand_context) }

    it 'returns a formatted user prompt with strategy JSON' do
      expect(subject).to be_a(String)
      expect(subject.length).to be > 100
    end

    it 'includes the strategy plan data header' do
      expect(subject).to include('# Strategy Plan Data (from StrategyPlanFormatter)')
    end

    it 'includes the brand context header' do
      expect(subject).to include('# Brand Context')
    end

    it 'contains the complete strategy JSON' do
      expect(subject).to include(strategy_plan_data.to_json)
    end

    it 'contains the brand context JSON' do
      expect(subject).to include(brand_context.to_json)
    end

    it 'includes brand and strategy information' do
      expect(subject).to include('"brand_name":"Test Brand"')
      expect(subject).to include('"strategy_name":"August Strategy 2025"')
      expect(subject).to include('"month":"2025-08"')
    end

    it 'includes content distribution data' do
      expect(subject).to include('"content_distribution"')
      expect(subject).to include('"Growth Strategy Tips"')
      expect(subject).to include('Want to grow your business?')
    end

    it 'includes weekly plan data' do
      expect(subject).to include('"weekly_plan"')
      expect(subject).to include('"Week 1 Growth Content"')
      expect(subject).to include('This week we focus on growth')
    end

    it 'handles empty strategy hash gracefully' do
      empty_strategy = {}
      empty_brand_context = {}
      result = described_class.voxa_user(strategy_plan_data: empty_strategy, brand_context: empty_brand_context)
      expect(result).to include('# Strategy Plan Data (from StrategyPlanFormatter)')
      expect(result).to include('{}')
    end

    it 'preserves complex nested structures in JSON' do
      expect(subject).to include('"publish_cadence":4')
      expect(subject).to include('"formats":["Video","Carousel"]')
      expect(subject).to include('"pilar":"C"')
    end
  end

  describe 'module behavior' do
    it 'can be included as a module' do
      expect(Creas::Prompts).to respond_to(:noctua_system)
      expect(Creas::Prompts).to respond_to(:noctua_user)
      expect(Creas::Prompts).to respond_to(:voxa_system)
      expect(Creas::Prompts).to respond_to(:voxa_user)
    end

    it 'uses module_function correctly' do
      # All methods should be available as module methods
      expect(Creas::Prompts.methods).to include(:noctua_system, :noctua_user, :voxa_system, :voxa_user)
    end
  end

  describe 'prompt content validation' do
    it 'noctua_system contains all required CREAS pillars' do
      prompt = described_class.noctua_system
      %w[C R E A S].each do |pillar|
        expect(prompt).to include(pillar)
      end
    end

    it 'voxa_system maintains consistency with noctua templates' do
      noctua = described_class.noctua_system
      voxa = described_class.voxa_system(strategy_plan_data: { brand_name: "Test" })

      # Both should reference the same template types
      templates = [ 'solo_avatars', 'avatar_and_video', 'narration_over_7_images', 'remix', 'one_to_three_videos' ]
      templates.each do |template|
        expect(noctua).to include(template)
        expect(voxa).to include(template)
      end
    end

    it 'both systems reference consistent KPI focuses' do
      noctua = described_class.noctua_system
      voxa = described_class.voxa_system(strategy_plan_data: { brand_name: "Test" })

      kpis = [ 'reach', 'saves', 'comments', 'CTR', 'DM' ]
      kpis.each do |kpi|
        expect(noctua).to include(kpi)
        expect(voxa).to include(kpi)
      end
    end

    it 'maintains consistent objective types across both systems' do
      noctua = described_class.noctua_system
      voxa = described_class.voxa_system(strategy_plan_data: { brand_name: "Test" })

      objectives = 'awareness | engagement | sales | community'
      expect(noctua).to include(objectives)
      expect(voxa).to include(objectives)
    end
  end
end
