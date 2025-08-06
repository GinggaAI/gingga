require "net/http"
require "json"

module Kling
  class ValidateKeyService
    API_URLS = {
      "test" => "https://api.kling.ai/v1/models",
      "production" => "https://api.kling.ai/v1/models"
    }.freeze

    def initialize(token:, mode:)
      @token = token
      @mode = mode
    end

    def call
      return { valid: false, error: "Invalid mode" } unless API_URLS.key?(@mode)

      response = make_request
      case response.code
      when "200"
        { valid: true }
      when "401", "403"
        { valid: false, error: "Invalid API key" }
      else
        { valid: false, error: "API validation failed with status #{response.code}" }
      end
    rescue StandardError => e
      { valid: false, error: "Network error: #{e.message}" }
    end

    private

    attr_reader :token, :mode

    def make_request
      uri = URI(API_URLS[@mode])
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@token}"
      request["Content-Type"] = "application/json"

      http.request(request)
    end
  end
end
