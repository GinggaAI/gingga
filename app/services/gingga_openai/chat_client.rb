module GinggaOpenAI
  class ChatClient
    def initialize(user:, model: Rails.application.config.openai_model, temperature: 0.4, timeout: 60)
      @client = ::OpenAI::Client.new(
        access_token: GinggaOpenAI::ClientForUser.access_token_for(user),
        request_timeout: timeout
      )
      @model = model
      @temperature = temperature
    end

    def chat!(system:, user:)
      tries = 0
      begin
        resp = @client.chat(
          parameters: {
            model: @model,
            temperature: @temperature,
            response_format: { type: "json_object" },
            messages: [
              { role: "system", content: system },
              { role: "user", content: user }
            ]
          }
        )
        content = resp.dig("choices", 0, "message", "content")
        raise "OpenAI empty response" if content.to_s.strip.empty?
        content
      rescue Faraday::TooManyRequestsError => e
        # Let ActiveJob retry handle rate limit errors with exponential backoff
        Rails.logger.warn "OpenAI rate limit exceeded (429), will retry with exponential backoff via ActiveJob..."
        raise e
      rescue Faraday::TimeoutError => e
        tries += 1
        if tries < 3
          Rails.logger.warn "OpenAI timeout (attempt #{tries}/3), retrying..."
          sleep(2 ** tries) # Exponential backoff: 2s, 4s
          retry
        end
        raise "OpenAI API timeout after #{tries} attempts. Please check your network connection and try again."
      rescue Faraday::ConnectionFailed => e
        raise "Unable to connect to OpenAI API. Please check your network connection and API key."
      rescue => e
        tries += 1
        if tries < 2 && !e.message.include?("timeout") && !e.message.include?("429")
          Rails.logger.warn "OpenAI error (attempt #{tries}/2): #{e.message}"
          retry
        end
        raise
      end
    end
  end
end
