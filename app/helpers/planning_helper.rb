module PlanningHelper
  # Rails-first approach: Use helper to render content pieces with proper business logic
  # This replaces JavaScript content rendering with server-side Ruby logic

  def render_content_piece_for_calendar(content_piece, presenter)
    platform = content_piece["platform"] || "Instagram"
    content_type = content_piece["type"] || content_piece["content_type"] || "Post"
    title = presenter.formatted_title_for_content(content_piece)
    status = content_piece["status"] || "draft"
    icon = presenter.content_icon_for(platform, content_type)

    status_classes = presenter.status_css_classes_for(status)
    status_badge = status != "draft" ? content_tag(:span, "", class: "inline-block w-2 h-2 rounded-full bg-current opacity-60 mr-1") : ""

    # Build card content
    card_content = "#{status_badge}#{icon} #{title}".html_safe

    # Add extra info for in_production posts
    if status == "in_production"
      extra_info = []
      if content_piece["hook"].present?
        hook_text = content_piece["hook"].length > 15 ? "#{content_piece["hook"][0...15]}..." : content_piece["hook"]
        extra_info << "🎣 #{hook_text}"
      end
      if content_piece["cta"].present?
        cta_text = content_piece["cta"].length > 15 ? "#{content_piece["cta"][0...15]}..." : content_piece["cta"]
        extra_info << "📢 #{cta_text}"
      end

      if extra_info.any?
        extra_div = content_tag(:div, extra_info.join("<br>").html_safe, class: "mt-1 text-[10px] opacity-75")
        card_content += extra_div
      end
    end

    # Build tooltip text
    tooltip_text = "#{title} (#{status.humanize})"
    if status == "in_production"
      tooltip_text += "\n🎣 Hook: #{content_piece["hook"]}" if content_piece["hook"].present?
      tooltip_text += "\n📢 CTA: #{content_piece["cta"]}" if content_piece["cta"].present?
    end

    content_tag(:div, card_content,
      class: "#{status_classes} text-xs p-2 rounded mb-2 cursor-pointer hover:opacity-80 transition-all",
      title: tooltip_text,
      data: { content_id: content_piece["id"] }
    )
  end

  def render_create_reel_button(content_piece, presenter)
    return "" unless presenter.show_create_reel_button_for_content?(content_piece)

    reel_data = presenter.format_content_for_reel_creation(content_piece)

    content_tag(:div, class: "mt-4 p-4 bg-gradient-to-r from-green-50 to-blue-50 rounded-lg border-l-4 border-green-500") do
      content_tag(:div, class: "flex items-center justify-between") do
        left_content = content_tag(:div) do
          title = content_tag(:h5, "🎬 Create Reel", class: "font-medium text-gray-900 mb-1")
          description = content_tag(:p, "This content is ready to be converted to a reel with preloaded data.", class: "text-sm text-gray-600")
          title + description
        end

        right_content = link_to(new_reel_path(template: content_piece["template"], smart_planning_data: reel_data.to_json),
          class: "bg-green-600 hover:bg-green-700 text-white font-medium px-4 py-2 rounded-lg transition-colors duration-200 flex items-center gap-2") do
          content_tag(:span, "🚀") + "Create Reel"
        end

        left_content + right_content
      end
    end
  end

  def render_content_scenes(content_piece, presenter)
    return "" unless content_piece["scenes"]&.any?

    content_tag(:div, class: "mt-4 p-3 bg-purple-50 rounded border-l-4 border-purple-500") do
      title = content_tag(:h5, "🎬 Shot Plan - Scenes", class: "font-medium text-gray-900 mb-3")

      scenes_content = content_tag(:div, class: "space-y-3") do
        content_piece["scenes"].map do |scene|
          render_single_scene(scene)
        end.join.html_safe
      end

      title + scenes_content
    end
  end

  def render_content_beats(content_piece, presenter)
    return "" unless presenter.show_beats_for_content?(content_piece)

    content_tag(:div, class: "mt-4 p-3 bg-amber-50 rounded border-l-4 border-amber-500") do
      title = content_tag(:h5, "📋 Shot Plan - Beats", class: "font-medium text-gray-900 mb-3")

      beats_content = content_tag(:div, class: "space-y-2") do
        content_piece["beats"].map do |beat|
          render_single_beat(beat)
        end.join.html_safe
      end

      title + beats_content
    end
  end

  private

  def render_single_scene(scene)
    content_tag(:div, class: "bg-white p-3 rounded border-l-2 border-purple-300") do
      header = content_tag(:div, class: "flex items-start justify-between mb-2") do
        scene_title = scene["scene_number"] ? "Scene #{scene["scene_number"]}" : "Scene"
        scene_title += " - #{scene["role"]}" if scene["role"]

        title_content = content_tag(:h6, scene_title, class: "font-semibold text-sm text-purple-800")
        duration_content = scene["duration"] ? content_tag(:span, scene["duration"], class: "text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded") : ""

        title_content + duration_content
      end

      body_parts = []
      body_parts << content_tag(:p, scene["description"], class: "text-sm text-gray-700 mb-2") if scene["description"]
      body_parts << content_tag(:p, class: "text-xs text-gray-600") { content_tag(:strong, "Visual: ") + scene["visual"] } if scene["visual"]
      body_parts << content_tag(:p, class: "text-xs text-gray-600") { content_tag(:strong, "On-screen text: ") + scene["on_screen_text"] } if scene["on_screen_text"]
      body_parts << content_tag(:p, class: "text-xs text-gray-600") { content_tag(:strong, "Voiceover: ") + scene["voiceover"] } if scene["voiceover"]

      if scene["visual_elements"]&.any?
        elements_content = content_tag(:div, class: "mt-2") do
          label = content_tag(:p, "Visual Elements:", class: "text-xs font-medium text-gray-600 mb-1")
          elements = content_tag(:div, class: "flex flex-wrap gap-1") do
            scene["visual_elements"].map do |element|
              content_tag(:span, element, class: "text-xs bg-purple-100 text-purple-700 px-2 py-1 rounded")
            end.join.html_safe
          end
          label + elements
        end
        body_parts << elements_content
      end

      body_parts << content_tag(:p, class: "text-xs text-gray-600 mt-1") { content_tag(:strong, "Avatar: ") + scene["avatar_id"] } if scene["avatar_id"]
      body_parts << content_tag(:p, class: "text-xs text-gray-600") { content_tag(:strong, "Voice: ") + scene["voice_id"] } if scene["voice_id"]

      header + body_parts.join.html_safe
    end
  end

  def render_single_beat(beat)
    content_tag(:div, class: "bg-white p-2 rounded border-l-2 border-amber-300") do
      header = content_tag(:div, class: "flex items-center justify-between") do
        beat_title = beat["beat_number"] ? "Beat #{beat["beat_number"]}" : "Beat"
        beat_title += " (#{beat["idx"]})" if beat["idx"]

        title_content = content_tag(:span, beat_title, class: "font-medium text-sm text-amber-800")
        duration_content = beat["duration"] ? content_tag(:span, beat["duration"], class: "text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded") : ""

        title_content + duration_content
      end

      body_parts = []
      body_parts << content_tag(:p, beat["description"], class: "text-sm text-gray-700 mt-1") if beat["description"]
      body_parts << content_tag(:p, class: "text-xs text-gray-600 mt-1") { content_tag(:strong, "Image: ") + beat["image_prompt"] } if beat["image_prompt"]
      body_parts << content_tag(:p, class: "text-xs text-gray-600") { content_tag(:strong, "Voiceover: ") + beat["voiceover"] } if beat["voiceover"]

      header + body_parts.join.html_safe
    end
  end
end
