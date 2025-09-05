require "ostruct"

class Heygen::ValidateAndSyncService
  def initialize(user:)
    @user = user
  end

  def call
    Rails.logger.info "🔄 Starting HeyGen avatar validation for user: #{@user.email}"

    heygen_token = @user.active_token_for("heygen")
    return failure_result("No valid HeyGen API token found") unless heygen_token

    group_url = heygen_token.group_url
    Rails.logger.info "🔗 [DEBUG] ValidateAndSyncService - group_url from token: #{group_url.inspect}"

    sync_result = Heygen::SynchronizeAvatarsService.new(user: @user, group_url: group_url).call

    Rails.logger.info "📊 Validation result: Success=#{sync_result.success?}, Data=#{sync_result.data&.keys}, Error=#{sync_result.error}"

    if sync_result.success?
      count = sync_result.data[:synchronized_count] || 0
      Rails.logger.info "✅ Successfully synchronized #{count} avatars"

      message_key = group_url.present? ? "settings.heygen.group_validation_success" : "settings.heygen.validation_success"
      success_result(count: count, message_key: message_key)
    else
      Rails.logger.error "❌ Avatar validation failed: #{sync_result.error}"
      failure_result("Validation failed: #{sync_result.error}")
    end
  rescue StandardError => e
    Rails.logger.error "❌ Avatar validation error: #{e.message}"
    failure_result("Error during validation: #{e.message}")
  end

  private

  def success_result(count:, message_key:)
    OpenStruct.new(
      success?: true,
      data: { synchronized_count: count, message_key: message_key },
      error: nil
    )
  end

  def failure_result(error_message)
    OpenStruct.new(success?: false, data: nil, error: error_message)
  end
end
