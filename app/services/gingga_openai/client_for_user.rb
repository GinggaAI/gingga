module GinggaOpenAI
  class ClientForUser
    def self.access_token_for(user)
      token = user&.active_token_for("openai")
      token&.encrypted_token || ENV["OPENAI_API_KEY"]
    end
  end
end
