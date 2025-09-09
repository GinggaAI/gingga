class CheckVideoStatusJob < ApplicationJob
  queue_as :default

  def perform(reel_id)
    reel = Reel.find_by(id: reel_id)
    return unless reel
    return unless reel.status == "processing"
    return unless reel.heygen_video_id.present?

    Rails.logger.info "🔍 Checking video status for reel #{reel.id}"

    result = Heygen::CheckVideoStatusService.new(reel.user, reel).call

    if result[:success]
      status_data = result[:data]
      Rails.logger.info "📹 Video status for reel #{reel.id}: #{status_data[:status]}"

      if status_data[:status] == "processing"
        # Schedule another check in 30 seconds
        CheckVideoStatusJob.set(wait: 30.seconds).perform_later(reel_id)
      elsif status_data[:status] == "completed"
        Rails.logger.info "✅ Video generation completed for reel #{reel.id}"
      elsif status_data[:status] == "failed"
        Rails.logger.error "❌ Video generation failed for reel #{reel.id}"
      end
    else
      Rails.logger.error "🚨 Error checking video status for reel #{reel.id}: #{result[:error]}"
      # Retry in 60 seconds if there's an API error
      CheckVideoStatusJob.set(wait: 60.seconds).perform_later(reel_id)
    end
  rescue StandardError => e
    Rails.logger.error "💥 Exception checking video status for reel #{reel_id}: #{e.message}"
    # Retry in 60 seconds on exception
    CheckVideoStatusJob.set(wait: 60.seconds).perform_later(reel_id) if reel_id
  end
end
