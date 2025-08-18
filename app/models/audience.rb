class Audience < ApplicationRecord
  belongs_to :brand

  validates :name, presence: true

  # Callbacks to convert string data to proper JSON arrays
  before_save :process_string_arrays
  before_save :process_demographic_profile

  private

  def process_string_arrays
    # Convert comma-separated strings to arrays
    if interests.is_a?(String) && interests.present?
      self.interests = interests.split(",").map(&:strip).reject(&:blank?)
    end

    if digital_behavior.is_a?(String) && digital_behavior.present?
      self.digital_behavior = digital_behavior.split(",").map(&:strip).reject(&:blank?)
    end
  end

  def process_demographic_profile
    # Parse JSON string if it's a string
    if demographic_profile.is_a?(String) && demographic_profile.present?
      begin
        self.demographic_profile = JSON.parse(demographic_profile)
      rescue JSON::ParserError
        # If JSON is invalid, set to empty hash
        self.demographic_profile = {}
      end
    end
  end
end
