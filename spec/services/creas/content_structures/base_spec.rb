# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Creas::ContentStructures::Base do
  # Create a test subclass for testing Base functionality
  let(:test_class) do
    Class.new(described_class) do
      def self.name
        'Creas::ContentStructures::TestStructure'
      end

      def self.config
        {
          name: "Test Structure",
          use_for: "Testing purposes",
          min_scenes: 6,
          max_scenes: 7,
          pillars: %w[C E],
          content_types: %w[test example]
        }
      end

      def self.template
        <<~TEMPLATE
          • Hook: Test hook
          • Body: Test body
          • Close: Test close
        TEMPLATE
      end
    end
  end

  describe '.config' do
    it 'must be implemented by subclasses' do
      expect { described_class.config }.to raise_error(NotImplementedError)
    end

    it 'returns configuration when implemented' do
      config = test_class.config

      expect(config).to be_a(Hash)
      expect(config[:name]).to eq("Test Structure")
      expect(config[:min_scenes]).to eq(6)
      expect(config[:max_scenes]).to eq(7)
    end
  end

  describe '.template' do
    it 'must be implemented by subclasses' do
      expect { described_class.template }.to raise_error(NotImplementedError)
    end

    it 'returns template when implemented' do
      template = test_class.template

      expect(template).to be_a(String)
      expect(template).to include("Hook")
      expect(template).to include("Body")
    end
  end

  describe '.structure_key' do
    it 'returns snake_case key from class name' do
      expect(test_class.structure_key).to eq('test_structure')
    end
  end

  describe '.to_prompt' do
    it 'generates formatted prompt for Voxa' do
      prompt = test_class.to_prompt

      expect(prompt).to include("Test Structure")
      expect(prompt).to include("test_structure")
      expect(prompt).to include("Use for: Testing purposes")
      expect(prompt).to include("Best for pillars: C, E")
      expect(prompt).to include("Scenes: 6-7")
      expect(prompt).to include("Hook: Test hook")
    end
  end

  describe '.compatible_with?' do
    it 'returns true when pilar is in allowed pillars' do
      expect(test_class.compatible_with?(pilar: 'C')).to be true
      expect(test_class.compatible_with?(pilar: 'E')).to be true
    end

    it 'returns false when pilar is not in allowed pillars' do
      expect(test_class.compatible_with?(pilar: 'R')).to be false
      expect(test_class.compatible_with?(pilar: 'A')).to be false
    end

    it 'checks content_type when provided' do
      expect(test_class.compatible_with?(pilar: 'C', content_type: 'test')).to be true
      expect(test_class.compatible_with?(pilar: 'C', content_type: 'invalid')).to be false
    end

    it 'ignores content_type when nil' do
      expect(test_class.compatible_with?(pilar: 'C', content_type: nil)).to be true
    end
  end
end
