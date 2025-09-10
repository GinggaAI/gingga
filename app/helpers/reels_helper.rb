module ReelsHelper
  def status_icon(status)
    # Sanitize input and ensure only safe, predefined icons are returned
    safe_status = status.to_s.strip

    case safe_status
    when "draft"
      "📝"
    when "processing"
      "⏳"
    when "completed"
      "✅"
    when "failed"
      "❌"
    else
      "📄"  # Safe default
    end
  end

  def status_icon_class(status)
    # Sanitize input and ensure only safe, predefined CSS classes are returned
    safe_status = status.to_s.strip

    css_class = case safe_status
    when "draft"
      "bg-gray-100"
    when "processing"
      "bg-yellow-100"
    when "completed"
      "bg-green-100"
    when "failed"
      "bg-red-100"
    else
      "bg-gray-100"  # Safe default
    end

    # Return as safe HTML to prevent XSS warnings
    css_class.html_safe
  end

  # Explicit safe method for status CSS class to satisfy security scanners
  def safe_status_css_class(status)
    # Only allow explicitly defined status values to prevent XSS
    allowed_statuses = %w[draft processing completed failed]

    if allowed_statuses.include?(status.to_s.strip)
      status_icon_class(status)
    else
      "bg-gray-100".html_safe  # Safe fallback
    end
  end

  def status_description(status)
    # Sanitize input and ensure only safe, predefined descriptions are returned
    safe_status = status.to_s.strip

    case safe_status
    when "draft"
      "This reel is saved as a draft and hasn't been generated yet."
    when "processing"
      "Your video is currently being generated with HeyGen. This usually takes a few minutes."
    when "completed"
      "Your video has been successfully generated and is ready to view!"
    when "failed"
      "There was an error generating your video. Please try creating a new reel."
    else
      "Unknown status"  # Safe default
    end
  end
end
