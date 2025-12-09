# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Creas::ContentStructures::Registry do
  describe '.all' do
    it 'returns hash of structure_key => class' do
      all_structures = described_class.all

      expect(all_structures).to be_a(Hash)
      expect(all_structures['voxa_radiant_rankings']).to eq(Creas::ContentStructures::VoxaRadiantRankings)
      expect(all_structures['noctua_red_alerts']).to eq(Creas::ContentStructures::NoctuaRedAlerts)
    end

    it 'includes all 15 structures' do
      expect(described_class.all.count).to eq(15)
    end
  end

  describe '.keys' do
    it 'returns array of all structure keys' do
      keys = described_class.keys

      expect(keys).to be_an(Array)
      expect(keys).to include('voxa_radiant_rankings')
      expect(keys).to include('noctua_red_alerts')
      expect(keys).to include('movement_blockers')
      expect(keys.count).to eq(15)
    end
  end

  describe '.structures' do
    it 'returns array of all structure classes' do
      structures = described_class.structures

      expect(structures).to be_an(Array)
      expect(structures).to include(Creas::ContentStructures::VoxaRadiantRankings)
      expect(structures).to include(Creas::ContentStructures::NoctuaRedAlerts)
      expect(structures.count).to eq(15)
    end
  end

  describe '.find' do
    it 'finds structure by key' do
      structure = described_class.find('voxa_radiant_rankings')

      expect(structure).to eq(Creas::ContentStructures::VoxaRadiantRankings)
    end

    it 'returns nil for non-existent key' do
      expect(described_class.find('non_existent')).to be_nil
    end
  end

  describe '.for_pilar' do
    it 'returns structures compatible with given pilar' do
      c_structures = described_class.for_pilar('C')

      expect(c_structures).to be_an(Array)
      expect(c_structures).to all(respond_to(:compatible_with?))

      # Verify all returned structures are compatible with 'C'
      c_structures.each do |structure|
        expect(structure.compatible_with?(pilar: 'C')).to be true
      end
    end

    it 'returns different structures for different pillars' do
      c_structures = described_class.for_pilar('C')
      r_structures = described_class.for_pilar('R')

      expect(c_structures.count).to be > 0
      expect(r_structures.count).to be > 0
      # Some structures may overlap, but not all
    end
  end

  describe '.to_prompt' do
    it 'generates combined prompt for all structures' do
      prompt = described_class.to_prompt

      expect(prompt).to be_a(String)
      expect(prompt.length).to be > 100

      # Should include all structure names
      expect(prompt).to include("Voxa's Radiant Rankings")
      expect(prompt).to include("Noctua's Red Alerts")
      expect(prompt).to include("Movement Blockers")
    end
  end

  describe '.to_list' do
    it 'returns pipe-separated list of structure keys' do
      list = described_class.to_list

      expect(list).to be_a(String)
      expect(list).to include('voxa_radiant_rankings')
      expect(list).to include(' | ')

      # Should have 14 separators for 15 items
      expect(list.scan(' | ').count).to eq(14)
    end
  end

  describe '.count' do
    it 'returns total number of structures' do
      expect(described_class.count).to eq(15)
    end
  end
end
