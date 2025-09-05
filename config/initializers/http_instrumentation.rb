# frozen_string_literal: true

# HTTP request instrumentation for observability
# This initializer logs all HTTP requests made via our Http::BaseClient

ActiveSupport::Notifications.subscribe("http.request") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  data = event.payload

  # Build a descriptive log message
  verb = data[:verb]
  base_url = data[:base_url]
  path = data[:path]
  status = data[:status]
  response_time = data[:response_time_ms] || event.duration.round(1)

  # Color code based on status for readability in development
  color_code = case status.to_i
  when 200..299 then "\e[32m" # Green for success
  when 400..499 then "\e[33m" # Yellow for client errors
  when 500..599 then "\e[31m" # Red for server errors
  else "\e[37m"               # White for others
  end

  reset_color = "\e[0m"

  log_message = if Rails.env.development?
                  "#{color_code}[HTTP]#{reset_color} #{verb} #{base_url}#{path} → #{status} (#{response_time}ms)"
  else
                  "[HTTP] #{verb} #{base_url}#{path} → #{status} (#{response_time}ms)"
  end

  Rails.logger.info(log_message)
end
