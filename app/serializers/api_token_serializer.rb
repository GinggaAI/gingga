class ApiTokenSerializer
  def initialize(api_token)
    @api_token = api_token
  end

  def as_json
    {
      id: @api_token.id,
      provider: @api_token.provider,
      mode: @api_token.mode,
      valid: @api_token.is_valid,
      created_at: @api_token.created_at,
      updated_at: @api_token.updated_at
    }
  end

  private

  attr_reader :api_token
end
