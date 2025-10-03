class ReelShowPresenter
  include ReelsHelper

  # Whitelisted CSS classes for security - only predefined values allowed
  STATUS_BADGE_CLASSES = {
    "draft" => "status-badge status-badge--draft",
    "processing" => "status-badge status-badge--processing",
    "completed" => "status-badge status-badge--completed",
    "failed" => "status-badge status-badge--failed"
  }.freeze

  def initialize(reel)
    @reel = reel
  end

  def title
    @reel.title.presence || "Untitled Reel"
  end

  def description
    @reel.description if @reel.description.present?
  end

  def status
    @reel.status
  end

  def status_titleized
    @reel.status.titleize
  end

  def status_badge_class
    # Use whitelisted hash lookup for security - prevents any user input injection
    # Only predefined CSS classes can be returned, fallback to safe default
    # Note: Removed .html_safe to let HAML handle escaping automatically
    STATUS_BADGE_CLASSES.fetch(status.to_s.strip, STATUS_BADGE_CLASSES["draft"])
  end

  def status_icon
    super(@reel.status)
  end

  def status_description
    super(@reel.status)
  end

  def template_humanized
    @reel.template.humanize
  end

  def created_at_formatted
    @reel.created_at.strftime("%B %d, %Y at %I:%M %p")
  end

  def heygen_video_id
    @reel.heygen_video_id
  end

  def video_url
    @reel.video_url
  end

  def thumbnail_url
    @reel.thumbnail_url
  end

  def duration
    @reel.duration
  end

  def show_video?
    status == "completed" && video_url.present?
  end

  def show_processing_indicator?
    status == "processing"
  end

  def show_error_message?
    status == "failed"
  end

  def processing_message
    "Your video is being generated with HeyGen..."
  end

  def processing_subtitle
    "This usually takes a few minutes. You can refresh this page to check the status."
  end

  def error_message
    "There was an error generating your video. Please try creating a new reel."
  end

  def duration_text
    "Duration: #{duration} seconds" if duration
  end

  def has_scenes?
    @reel.reel_scenes.any?
  end

  def ordered_scenes
    @reel.reel_scenes.ordered
  end
end
