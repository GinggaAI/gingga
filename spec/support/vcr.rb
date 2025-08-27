require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter out API keys from cassettes
  config.filter_sensitive_data('<OPENAI_API_KEY>') { ENV['OPENAI_API_KEY'] }

  # Ignore localhost and test requests
  config.ignore_localhost = true

  # Allow real connections during recording if needed
  config.allow_http_connections_when_no_cassette = false

  # Default cassette options
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [ :method, :uri, :headers, :body ]
  }
end
