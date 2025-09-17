module Ui
  class PlanningComponent < ViewComponent::Base
    def initialize(content_piece:, presenter:)
      @content_piece = content_piece
      @presenter = presenter
    end

    def show_create_reel_button?
      presenter.show_create_reel_button_for_content?(content_piece)
    end

    def show_content_scenes?
      content_piece["scenes"]&.any? || false
    end

    def show_content_beats?
      presenter.show_beats_for_content?(content_piece)
    end

    def reel_data
      presenter.format_content_for_reel_creation(content_piece)
    end

    def content_scenes
      content_piece["scenes"] || []
    end

    def content_beats
      content_piece["beats"] || []
    end

    def scene_title_for(scene)
      title = scene["scene_number"] ? "#{t('planning.content_pieces.scene')} #{scene["scene_number"]}" : t("planning.content_pieces.scene")
      title += " - #{scene["role"]}" if scene["role"]
      title
    end

    def beat_title_for(beat)
      title = beat["beat_number"] ? "#{t('planning.content_pieces.beat')} #{beat["beat_number"]}" : t("planning.content_pieces.beat")
      title += " (#{beat["idx"]})" if beat["idx"]
      title
    end

    def new_reel_path_with_data
      new_reel_path(template: content_piece["template"], smart_planning_data: reel_data.to_json)
    end

    # Calendar card for content piece - this method is for potential future calendar use
    def render_content_piece_for_calendar
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

      # Build tooltip text - defer translation to render time if needed
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

    private

    attr_reader :content_piece, :presenter
  end
end
