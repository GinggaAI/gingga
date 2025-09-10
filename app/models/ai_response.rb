class AiResponse < ApplicationRecord
  belongs_to :user

  validates :service_name, presence: true
  validates :ai_model, presence: true
  validates :raw_response, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_service, ->(service) { where(service_name: service) }
  scope :by_model, ->(model) { where(ai_model: model) }
  scope :by_version, ->(version) { where(prompt_version: version) }

  def parsed_response
    @parsed_response ||= JSON.parse(raw_response) if raw_response.is_a?(String)
    @parsed_response ||= raw_response if raw_response.is_a?(Hash)
    @parsed_response
  rescue JSON::ParserError => e
    Rails.logger.warn "AiResponse #{id}: Failed to parse raw_response JSON for #{service_name}/#{ai_model}: #{e.message}"
    nil
  end

  def response_summary
    return "Invalid JSON" unless parsed_response

    case service_name
    when "noctua"
      frequency = parsed_response.dig("frequency_per_week")
      weekly_plan = parsed_response.dig("weekly_plan")
      if weekly_plan&.is_a?(Array)
        week_counts = weekly_plan.map { |week| week.dig("ideas")&.count || 0 }
        "#{frequency}/week target, actual: #{week_counts.join('-')} (total: #{week_counts.sum})"
      else
        "No weekly_plan found"
      end
    when "voxa"
      items = parsed_response.dig("items")&.count || 0
      "Generated #{items} content items"
    else
      "Unknown service"
    end
  end
end
