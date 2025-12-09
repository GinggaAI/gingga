# frozen_string_literal: true

module Creas
  module ContentStructures
    class Registry
      # All available content structures
      STRUCTURES = [
        VoxaRadiantRankings,
        NoctuaRedAlerts,
        MovementBlockers,
        SecretsFromLivingBook,
        AlumoAlignmentSignals,
        ImpactTriad,
        ShadowsTriad,
        NoctuaHiddenTruths,
        ThingsYouDidntKnow,
        AwakeningData,
        ChroniclesInMotion,
        FrictionEchoes,
        SaguiRationale,
        SaguiInfiniteLoop,
        HeroInnerForge
      ].freeze

      class << self
        # Returns a hash of structure_key => class
        # Example: { "voxa_radiant_rankings" => VoxaRadiantRankings, ... }
        def all
          @all ||= STRUCTURES.index_by(&:structure_key)
        end

        # Returns array of all structure keys
        # Example: ["voxa_radiant_rankings", "noctua_red_alerts", ...]
        def keys
          all.keys
        end

        # Returns array of all structure classes
        def structures
          STRUCTURES
        end

        # Find a structure by key
        # Example: Registry.find("voxa_radiant_rankings")
        def find(key)
          all[key]
        end

        # Find structures compatible with given pilar
        # Example: Registry.for_pilar("C")
        def for_pilar(pilar)
          STRUCTURES.select { |structure| structure.compatible_with?(pilar: pilar) }
        end

        # Generate combined prompt for all structures
        # Used in voxa_system prompt
        def to_prompt
          STRUCTURES.map(&:to_prompt).join("\n")
        end

        # Generate a formatted list for prompt
        # Example: "voxa_radiant_rankings | noctua_red_alerts | ..."
        def to_list
          keys.join(" | ")
        end

        # Count of available structures
        def count
          STRUCTURES.count
        end
      end
    end
  end
end
