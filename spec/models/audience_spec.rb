require 'rails_helper'

RSpec.describe Audience, type: :model do
  let(:brand) { create(:brand) }

  describe 'associations' do
    it { should belong_to(:brand) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }

    it 'is valid with valid attributes' do
      audience = build(:audience, brand: brand)
      expect(audience).to be_valid
    end

    it 'is invalid without a name' do
      audience = build(:audience, brand: brand, name: nil)
      expect(audience).not_to be_valid
      expect(audience.errors[:name]).to include("can't be blank")
    end

    it 'is invalid with a blank name' do
      audience = build(:audience, brand: brand, name: '')
      expect(audience).not_to be_valid
      expect(audience.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a brand' do
      audience = build(:audience, brand: nil)
      expect(audience).not_to be_valid
    end
  end

  describe 'JSONB defaults' do
    let(:audience) { create(:audience, brand: brand) }

    it 'has default empty hash for demographic_profile' do
      expect(audience.demographic_profile).to be_a(Hash)
    end

    it 'has default empty arrays for interests' do
      expect(audience.interests).to be_an(Array)
    end

    it 'has default empty arrays for digital_behavior' do
      expect(audience.digital_behavior).to be_an(Array)
    end
  end

  describe 'callbacks' do
    describe '#process_string_arrays' do
      context 'when interests is a string' do
        it 'converts comma-separated string to array' do
          audience = create(:audience,
                           brand: brand,
                           interests: 'technology, innovation, productivity')

          expect(audience.interests).to eq([ 'technology', 'innovation', 'productivity' ])
        end

        it 'strips whitespace from array elements' do
          audience = create(:audience,
                           brand: brand,
                           interests: ' technology ,  innovation  , productivity ')

          expect(audience.interests).to eq([ 'technology', 'innovation', 'productivity' ])
        end

        it 'rejects blank elements' do
          audience = create(:audience,
                           brand: brand,
                           interests: 'technology, , innovation, , productivity')

          expect(audience.interests).to eq([ 'technology', 'innovation', 'productivity' ])
        end

        it 'handles empty string' do
          audience = create(:audience,
                           brand: brand,
                           interests: '')

          expect(audience.interests).to eq('')
        end

        it 'handles single item' do
          audience = create(:audience,
                           brand: brand,
                           interests: 'technology')

          expect(audience.interests).to eq([ 'technology' ])
        end

        it 'handles string with only commas and spaces' do
          audience = create(:audience,
                           brand: brand,
                           interests: ' , , , ')

          expect(audience.interests).to eq([])
        end
      end

      context 'when interests is already an array' do
        it 'leaves arrays unchanged' do
          interests_array = [ 'technology', 'innovation' ]
          audience = create(:audience,
                           brand: brand,
                           interests: interests_array)

          expect(audience.interests).to eq(interests_array)
        end
      end

      context 'when interests is not a string' do
        it 'leaves non-string values unchanged' do
          interests_hash = { "tech" => "technology" }
          audience = create(:audience,
                           brand: brand,
                           interests: interests_hash)

          expect(audience.interests).to eq(interests_hash)
        end

        it 'leaves numeric values unchanged' do
          # Using build instead of create to bypass factory defaults
          audience = build(:audience, brand: brand, name: 'Test')
          audience.interests = 12345  # Non-string type
          audience.digital_behavior = []
          audience.demographic_profile = {}
          audience.save!

          expect(audience.interests).to eq(12345)
        end
      end

      context 'when interests is not present' do
        it 'handles blank string interests' do
          audience = build(:audience, brand: brand, name: 'Test')
          audience.interests = '   '  # Whitespace only, not considered present?
          audience.digital_behavior = []
          audience.demographic_profile = {}

          # This should not trigger the string processing logic
          original_interests = audience.interests
          audience.save!
          expect(audience.interests).to eq(original_interests)
        end
      end

      context 'when digital_behavior is a string' do
        it 'converts comma-separated string to array' do
          audience = create(:audience,
                           brand: brand,
                           digital_behavior: 'social_media_active, early_adopter, online_shopper')

          expect(audience.digital_behavior).to eq([ 'social_media_active', 'early_adopter', 'online_shopper' ])
        end

        it 'strips whitespace from array elements' do
          audience = create(:audience,
                           brand: brand,
                           digital_behavior: ' social_media_active ,  early_adopter  ')

          expect(audience.digital_behavior).to eq([ 'social_media_active', 'early_adopter' ])
        end

        it 'rejects blank elements' do
          audience = create(:audience,
                           brand: brand,
                           digital_behavior: 'social_media_active, , early_adopter')

          expect(audience.digital_behavior).to eq([ 'social_media_active', 'early_adopter' ])
        end

        it 'handles empty string' do
          audience = create(:audience,
                           brand: brand,
                           digital_behavior: '')

          expect(audience.digital_behavior).to eq('')
        end
      end

      context 'when digital_behavior is already an array' do
        it 'leaves arrays unchanged' do
          behavior_array = [ 'social_media_active', 'early_adopter' ]
          audience = create(:audience,
                           brand: brand,
                           digital_behavior: behavior_array)

          expect(audience.digital_behavior).to eq(behavior_array)
        end
      end

      context 'when digital_behavior is not a string' do
        it 'leaves non-string values unchanged' do
          behavior_hash = { "active" => "very" }
          audience = create(:audience,
                           brand: brand,
                           digital_behavior: behavior_hash)

          expect(audience.digital_behavior).to eq(behavior_hash)
        end

        it 'leaves numeric values unchanged' do
          audience = build(:audience, brand: brand, name: 'Test')
          audience.interests = []
          audience.digital_behavior = 12345
          audience.demographic_profile = {}
          audience.save!

          expect(audience.digital_behavior).to eq(12345)
        end
      end

      context 'when digital_behavior is not present' do
        it 'handles blank string digital_behavior' do
          audience = build(:audience, brand: brand, name: 'Test')
          audience.interests = []
          audience.digital_behavior = '   '  # Whitespace only
          audience.demographic_profile = {}

          original_behavior = audience.digital_behavior
          audience.save!
          expect(audience.digital_behavior).to eq(original_behavior)
        end
      end
    end

    describe '#process_demographic_profile' do
      context 'when demographic_profile is a JSON string' do
        it 'parses valid JSON string to hash' do
          json_string = '{"age_range": "25-34", "gender": "female", "location": "US"}'
          audience = create(:audience,
                           brand: brand,
                           demographic_profile: json_string)

          expected_hash = { "age_range" => "25-34", "gender" => "female", "location" => "US" }
          expect(audience.demographic_profile).to eq(expected_hash)
        end

        it 'handles complex JSON with nested structures' do
          json_string = '{"age_range": "25-34", "interests": ["tech", "sports"], "location": {"country": "US", "state": "CA"}}'
          audience = create(:audience,
                           brand: brand,
                           demographic_profile: json_string)

          expected_hash = {
            "age_range" => "25-34",
            "interests" => [ "tech", "sports" ],
            "location" => { "country" => "US", "state" => "CA" }
          }
          expect(audience.demographic_profile).to eq(expected_hash)
        end

        it 'handles empty JSON object string' do
          audience = create(:audience,
                           brand: brand,
                           demographic_profile: '{}')

          expect(audience.demographic_profile).to eq({})
        end
      end

      context 'when demographic_profile is invalid JSON string' do
        it 'sets to empty hash for invalid JSON' do
          audience = create(:audience,
                           brand: brand,
                           demographic_profile: '{"invalid": json}')

          expect(audience.demographic_profile).to eq({})
        end

        it 'sets to empty hash for malformed JSON' do
          audience = create(:audience,
                           brand: brand,
                           demographic_profile: '{age_range: 25-34}')

          expect(audience.demographic_profile).to eq({})
        end

        it 'sets to empty hash for completely invalid string' do
          audience = create(:audience,
                           brand: brand,
                           demographic_profile: 'not json at all')

          expect(audience.demographic_profile).to eq({})
        end
      end

      context 'when demographic_profile is already a hash' do
        it 'leaves hash unchanged' do
          profile_hash = { "age_range" => "25-34", "gender" => "all" }
          audience = create(:audience,
                           brand: brand,
                           demographic_profile: profile_hash)

          expect(audience.demographic_profile).to eq(profile_hash)
        end
      end

      context 'when demographic_profile is not a string' do
        it 'leaves non-string values unchanged' do
          profile_array = [ "age", "25-34" ]
          audience = create(:audience,
                           brand: brand,
                           demographic_profile: profile_array)

          expect(audience.demographic_profile).to eq(profile_array)
        end

        it 'leaves numeric values unchanged' do
          audience = build(:audience, brand: brand, name: 'Test')
          audience.interests = []
          audience.digital_behavior = []
          audience.demographic_profile = 999
          audience.save!

          expect(audience.demographic_profile).to eq(999)
        end
      end

      context 'when demographic_profile is not present' do
        it 'handles blank string demographic_profile' do
          audience = build(:audience, brand: brand, name: 'Test')
          audience.interests = []
          audience.digital_behavior = []
          audience.demographic_profile = '   '  # Whitespace only, not present?

          original_profile = audience.demographic_profile
          audience.save!
          expect(audience.demographic_profile).to eq(original_profile)
        end
      end

      context 'when demographic_profile is empty' do
        it 'handles empty string demographic_profile' do
          audience = create(:audience,
                           brand: brand,
                           demographic_profile: '')

          expect(audience.demographic_profile).to eq('')
        end

        it 'handles whitespace-only string' do
          audience = create(:audience,
                           brand: brand,
                           demographic_profile: '   ')

          expect(audience.demographic_profile).to eq('   ')
        end
      end
    end

    describe 'before_save callbacks execution' do
      it 'executes both callbacks on save' do
        audience = build(:audience,
                        brand: brand,
                        interests: 'tech, innovation',
                        digital_behavior: 'active, engaged',
                        demographic_profile: '{"age": "25-34"}')

        expect(audience).to receive(:process_string_arrays).and_call_original
        expect(audience).to receive(:process_demographic_profile).and_call_original

        audience.save!
      end

      it 'processes all fields correctly in a single save' do
        audience = build(:audience,
                        brand: brand,
                        name: 'Test Audience',
                        interests: 'technology, innovation, productivity',
                        digital_behavior: 'social_media_active, early_adopter',
                        demographic_profile: '{"age_range": "25-34", "location": "global"}')

        audience.save!
        audience.reload

        expect(audience.interests).to eq([ 'technology', 'innovation', 'productivity' ])
        expect(audience.digital_behavior).to eq([ 'social_media_active', 'early_adopter' ])
        expect(audience.demographic_profile).to eq({ "age_range" => "25-34", "location" => "global" })
      end
    end
  end

  describe 'factory' do
    it 'creates a valid audience' do
      audience = create(:audience, brand: brand)
      expect(audience).to be_valid
      expect(audience.name).to eq('Primary Audience')
    end

    it 'can override factory attributes' do
      audience = create(:audience,
                       brand: brand,
                       name: 'Custom Audience',
                       interests: [ 'custom', 'interests' ])

      expect(audience.name).to eq('Custom Audience')
      expect(audience.interests).to eq([ 'custom', 'interests' ])
    end
  end

  describe 'edge cases and error handling' do
    it 'handles very long comma-separated strings' do
      long_interests = Array.new(100) { |i| "interest_#{i}" }.join(', ')
      audience = create(:audience,
                       brand: brand,
                       interests: long_interests)

      expect(audience.interests).to be_an(Array)
      expect(audience.interests.size).to eq(100)
    end

    it 'handles special characters in interests' do
      audience = create(:audience,
                       brand: brand,
                       interests: 'tech & innovation, AI/ML, crypto-currency')

      expect(audience.interests).to eq([ 'tech & innovation', 'AI/ML', 'crypto-currency' ])
    end

    it 'handles unicode characters' do
      audience = create(:audience,
                       brand: brand,
                       interests: 'tecnología, innovación, productividad')

      expect(audience.interests).to eq([ 'tecnología', 'innovación', 'productividad' ])
    end

    it 'handles mixed data types gracefully' do
      # This tests that the model doesn't break with unexpected data
      audience = build(:audience, brand: brand)

      # Direct assignment bypassing validations to test callback robustness
      audience.interests = 123  # Not a string or array
      audience.digital_behavior = 'valid_behavior'  # Keep valid since NOT NULL constraint
      audience.demographic_profile = []  # Array instead of string or hash

      expect { audience.save! }.not_to raise_error
    end

    it 'handles unexpected object types in callbacks' do
      # Test with different object types that should not cause errors
      audience = build(:audience, brand: brand)

      # These assignments test callback robustness with edge cases
      audience.interests = { "not" => "an_array" }  # Hash instead of array/string
      audience.digital_behavior = 12345  # Number
      audience.demographic_profile = "not_json_but_valid_string"

      expect { audience.save! }.not_to raise_error
    end
  end
end
