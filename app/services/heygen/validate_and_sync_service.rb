require "ostruct"

class Heygen::ValidateAndSyncService
  def initialize(user:, voices_count: nil)
    @user = user
    @voices_count = voices_count
  end

  def call
    Rails.logger.info "🔄 Starting HeyGen avatar validation for user: #{@user.email}"

    heygen_token = @user.active_token_for("heygen")
    return failure_result("No valid HeyGen API token found") unless heygen_token

    group_url = heygen_token.group_url
    Rails.logger.info "🔗 [DEBUG] ValidateAndSyncService - group_url from token: #{group_url.inspect}"

    # Synchronize avatars
    avatars_sync_result = Heygen::SynchronizeAvatarsService.new(user: @user, group_url: group_url).call

    Rails.logger.info "📊 Avatar sync result: Success=#{avatars_sync_result.success?}, Data=#{avatars_sync_result.data&.keys}, Error=#{avatars_sync_result.error}"

    return failure_result("Avatar synchronization failed: #{avatars_sync_result.error}") unless avatars_sync_result.success?

    avatar_count = avatars_sync_result.data[:synchronized_count] || 0
    Rails.logger.info "✅ Successfully synchronized #{avatar_count} avatars"

    # Synchronize voices
    voices_sync_result = Heygen::SynchronizeVoicesService.new(user: @user, voices_count: @voices_count).call

    Rails.logger.info "🎵 Voice sync result: Success=#{voices_sync_result.success?}, Data=#{voices_sync_result.data&.keys}, Error=#{voices_sync_result.error}"

    if voices_sync_result.success?
      voice_count = voices_sync_result.data[:synchronized_count] || 0
      Rails.logger.info "✅ Successfully synchronized #{voice_count} voices"

      message_key = group_url.present? ? "settings.heygen.group_validation_success" : "settings.heygen.validation_success"
      success_result(avatar_count: avatar_count, voice_count: voice_count, message_key: message_key)
    else
      # Voices sync failure shouldn't fail the entire operation, just log it
      Rails.logger.warn "⚠️ Voice synchronization failed (continuing): #{voices_sync_result.error}"
      
      message_key = group_url.present? ? "settings.heygen.group_validation_success" : "settings.heygen.validation_success"
      success_result(avatar_count: avatar_count, voice_count: 0, message_key: message_key, voice_error: voices_sync_result.error)
    end
  rescue StandardError => e
    Rails.logger.error "❌ Avatar validation error: #{e.message}"
    failure_result("Error during validation: #{e.message}")
  end

  private

  def success_result(avatar_count:, voice_count:, message_key:, voice_error: nil)
    OpenStruct.new(
      success?: true,
      data: { 
        synchronized_count: avatar_count, # Keep for backward compatibility
        avatar_count: avatar_count,
        voice_count: voice_count,
        message_key: message_key,
        voice_error: voice_error
      },
      error: nil
    )
  end

  def failure_result(error_message)
    OpenStruct.new(success?: false, data: nil, error: error_message)
  end
end
