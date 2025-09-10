class ApiResponse < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true, inclusion: { in: %w[openai heygen kling] }
  validates :endpoint, presence: true

  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :recent, -> { order(created_at: :desc) }

  def self.log_api_call(provider:, endpoint:, user:, request_data: nil, response_data: nil,
                       status_code: nil, response_time_ms: nil, success: false, error_message: nil)
    create!(
      provider: provider,
      endpoint: endpoint,
      user: user,
      request_data: request_data&.to_json,
      response_data: response_data&.to_json,
      status_code: status_code,
      response_time_ms: response_time_ms,
      success: success,
      error_message: error_message
    )
  rescue StandardError => e
    Rails.logger.error "Failed to log API response: #{e.message}"
  end

  def parsed_request_data
    return {} unless request_data.present?
    JSON.parse(request_data)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse request_data JSON for ApiResponse ID #{id}: #{e.message}. Data: #{request_data.truncate(200)}"
    {}
  end

  def parsed_response_data
    return {} unless response_data.present?
    JSON.parse(response_data)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse response_data JSON for ApiResponse ID #{id}: #{e.message}. Data: #{response_data.truncate(200)}"
    {}
  end
end
