class ApiToken < ApplicationRecord
  belongs_to :user

  encrypts :encrypted_token

  validates :provider, presence: true, inclusion: { in: %w[openai heygen kling] }
  validates :mode, presence: true, inclusion: { in: %w[test production] }
  validates :encrypted_token, presence: true
  validates :provider, uniqueness: { scope: [ :user_id, :mode ] }

  scope :test_mode, -> { where(mode: "test") }
  scope :production_mode, -> { where(mode: "production") }
  scope :valid_tokens, -> { where(is_valid: true) }

  before_save :validate_token_with_provider

  private

  def validate_token_with_provider
    result = ApiTokenValidatorService.new(
      provider: provider,
      token: encrypted_token,
      mode: mode
    ).call

    unless result[:valid]
      errors.add(:encrypted_token, result[:error] || "Invalid token for #{provider}")
      throw(:abort)
    end

    self.is_valid = true
  rescue StandardError => e
    errors.add(:encrypted_token, "Validation failed: #{e.message}")
    throw(:abort)
  end
end
