class Heygen::SynchronizeVoicesService
  def initialize(user:, voices_count: nil)
    @user = user
    @voices_count = voices_count
  end

  def call
    list_result = fetch_voices

    return failure_result("Failed to fetch voices from HeyGen: #{list_result[:error]}") unless list_result[:success]

    voices_data = list_result[:data] || []

    raw_response = build_raw_response(voices_data)

    synchronized_voices = []

    voices_data.each do |voice_data|
      voice = sync_voice(voice_data, raw_response)
      synchronized_voices << voice if voice
    end

    success_result(data: {
      synchronized_count: synchronized_voices.size,
      total_fetched: voices_data.size,
      voices: synchronized_voices
    })
  rescue StandardError => e
    failure_result("Error synchronizing voices: #{e.message}")
  end

  private

  def fetch_voices
    Heygen::ListVoicesService.new(@user, {}, voices_count: @voices_count).call
  end

  def sync_voice(voice_data, raw_response)
    # Map the voice data from ListVoicesService format to Voice model format
    voice_attributes = {
      voice_id: voice_data[:id],
      language: voice_data[:language],
      gender: voice_data[:gender] || "unknown",
      name: voice_data[:name],
      preview_audio: voice_data[:preview_audio_url], # This should be nil based on our filter
      support_pause: true, # Default values as we don't have this data from the API
      emotion_support: false,
      support_interactive_avatar: false,
      support_locale: false,
      active: true
    }

    # Use the Voice model's sync method or find/create manually
    voice = @user.voices.find_or_initialize_by(voice_id: voice_attributes[:voice_id])

    # Update attributes
    voice.assign_attributes(voice_attributes)

    if voice.save
      voice
    else
      Rails.logger.error "Failed to sync voice #{voice_attributes[:voice_id]}: #{voice.errors.full_messages.join(', ')}"
      nil
    end
  end

  def build_raw_response(voices_data)
    {
      "code" => 100,
      "data" => {
        "voices" => voices_data
      }
    }.to_json
  end

  def success_result(data:)
    OpenStruct.new(success?: true, data: data, error: nil)
  end

  def failure_result(error_message)
    OpenStruct.new(success?: false, data: nil, error: error_message)
  end
end
