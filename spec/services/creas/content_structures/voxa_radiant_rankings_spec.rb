# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Creas::ContentStructures::VoxaRadiantRankings do
  describe '.config' do
    subject(:config) { described_class.config }

    it 'has required configuration keys' do
      expect(config).to include(
        :name,
        :use_for,
        :min_scenes,
        :max_scenes,
        :pillars,
        :content_types
      )
    end

    it 'has correct name' do
      expect(config[:name]).to eq("Voxa's Radiant Rankings")
    end

    it 'specifies scene range' do
      expect(config[:min_scenes]).to eq(6)
      expect(config[:max_scenes]).to eq(7)
    end

    it 'defines compatible pillars' do
      expect(config[:pillars]).to eq(%w[C E A])
    end

    it 'defines content types' do
      expect(config[:content_types]).to include('list', 'ranking', 'recommendation')
    end
  end

  describe '.template' do
    subject(:template) { described_class.template }

    it 'includes essential structure elements' do
      expect(template).to include('Hook')
      expect(template).to include('Authority')
      expect(template).to include('Countdown')
    end

    it 'includes ranking pattern' do
      expect(template).to include('Top X')
      expect(template).to include('#X → #1')
    end

    it 'includes closing element' do
      expect(template).to include('favorite')
    end
  end

  describe '.structure_key' do
    it 'returns correct snake_case key' do
      expect(described_class.structure_key).to eq('voxa_radiant_rankings')
    end
  end

  describe '.compatible_with?' do
    it 'is compatible with C pilar' do
      expect(described_class.compatible_with?(pilar: 'C')).to be true
    end

    it 'is compatible with E pilar' do
      expect(described_class.compatible_with?(pilar: 'E')).to be true
    end

    it 'is compatible with A pilar' do
      expect(described_class.compatible_with?(pilar: 'A')).to be true
    end

    it 'is not compatible with R pilar' do
      expect(described_class.compatible_with?(pilar: 'R')).to be false
    end

    it 'is compatible with ranking content type' do
      expect(described_class.compatible_with?(pilar: 'C', content_type: 'ranking')).to be true
    end

    it 'is compatible with list content type' do
      expect(described_class.compatible_with?(pilar: 'C', content_type: 'list')).to be true
    end
  end

  describe '.to_prompt' do
    subject(:prompt) { described_class.to_prompt }

    it 'generates formatted prompt' do
      expect(prompt).to include("Voxa's Radiant Rankings")
      expect(prompt).to include('voxa_radiant_rankings')
      expect(prompt).to include('Use for:')
      expect(prompt).to include('Best for pillars: C, E, A')
      expect(prompt).to include('Scenes: 6-7')
    end

    it 'includes template content' do
      expect(prompt).to include('Hook')
      expect(prompt).to include('Authority')
    end
  end
end
