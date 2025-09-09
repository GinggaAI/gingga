module ReelsHelper
  def status_icon(status)
    case status
    when "draft"
      "📝"
    when "processing"
      "⏳"
    when "completed"
      "✅"
    when "failed"
      "❌"
    else
      "📄"
    end
  end

  def status_icon_class(status)
    case status
    when "draft"
      "bg-gray-100"
    when "processing"
      "bg-yellow-100"
    when "completed"
      "bg-green-100"
    when "failed"
      "bg-red-100"
    else
      "bg-gray-100"
    end
  end

  def status_description(status)
    case status
    when "draft"
      "This reel is saved as a draft and hasn't been generated yet."
    when "processing"
      "Your video is currently being generated with HeyGen. This usually takes a few minutes."
    when "completed"
      "Your video has been successfully generated and is ready to view!"
    when "failed"
      "There was an error generating your video. Please try creating a new reel."
    else
      "Unknown status"
    end
  end
end