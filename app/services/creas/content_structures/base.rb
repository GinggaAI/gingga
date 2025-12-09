# frozen_string_literal: true

module Creas
  module ContentStructures
    class Base
      class << self
        # Returns the configuration for this content structure
        # Override in subclasses
        def config
          raise NotImplementedError, "#{name} must implement .config"
        end

        # Returns the template/prompt for this content structure
        # Override in subclasses
        def template
          raise NotImplementedError, "#{name} must implement .template"
        end

        # Returns the snake_case key for this structure
        # Example: VoxaRadiantRankings → "voxa_radiant_rankings"
        def structure_key
          name.demodulize.underscore
        end

        # Generates the formatted prompt for Voxa
        def to_prompt
          cfg = config

          <<~PROMPT
            #{cfg[:name]} (#{structure_key})
              Use for: #{cfg[:use_for]}
              Best for pillars: #{cfg[:pillars].join(', ')}
              Scenes: #{cfg[:min_scenes]}-#{cfg[:max_scenes]}

              Structure:
            #{template.indent(2)}
          PROMPT
        end

        # Validates if this structure is compatible with given parameters
        def compatible_with?(pilar:, content_type: nil)
          return false unless config[:pillars].include?(pilar)
          return true if content_type.nil?
          return true unless config[:content_types]

          config[:content_types].include?(content_type)
        end
      end
    end
  end
end
