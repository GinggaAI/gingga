module ApplicationHelper
  def menu_item_style(path)
    menu_item_active?(path) ? "color: #000000;" : "color: rgba(255,255,255,0.7);"
  end

  def menu_item_class(path)
    menu_item_active?(path) ? "active" : ""
  end

  def reel_icon_class(reel)
    case reel.template
    when "only_avatars", "avatar_and_video"
      "bg-gradient-to-r from-purple-500 to-pink-500"
    when "narration_over_7_images"
      "bg-blue-600"
    when "one_to_three_videos"
      "bg-black"
    else
      "bg-gray-500"
    end
  end

  def reel_icon_svg(reel)
    case reel.template
    when "only_avatars", "avatar_and_video"
      content_tag(:svg, class: "lucide lucide-video w-4 h-4", fill: "none", height: "24", stroke: "currentColor", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", viewBox: "0 0 24 24", width: "24", xmlns: "http://www.w3.org/2000/svg") do
        concat content_tag(:path, "", d: "m16 13 5.223 3.482a.5.5 0 0 0 .777-.416V7.87a.5.5 0 0 0-.752-.432L16 10.5")
        concat content_tag(:rect, "", height: "12", rx: "2", width: "14", x: "2", y: "6")
      end
    else
      content_tag(:svg, class: "lucide lucide-video w-4 h-4", fill: "none", height: "24", stroke: "currentColor", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", viewBox: "0 0 24 24", width: "24", xmlns: "http://www.w3.org/2000/svg") do
        concat content_tag(:path, "", d: "m16 13 5.223 3.482a.5.5 0 0 0 .777-.416V7.87a.5.5 0 0 0-.752-.432L16 10.5")
        concat content_tag(:rect, "", height: "12", rx: "2", width: "14", x: "2", y: "6")
      end
    end
  end

  def reel_display_title(reel)
    case reel.template
    when "only_avatars"
      "Only Avatar Video"
    when "avatar_and_video"
      "Avatar & Video Reel"
    when "narration_over_7_images"
      "Narrated Image Reel"
    when "one_to_three_videos"
      "Multi-Video Reel"
    else
      "Video Content"
    end
  end

  def reel_type_display(reel)
    "reel"
  end

  # Safe path helpers that include brand_slug and locale
  def safe_my_brand_path
    return my_brand_path if current_brand.nil?
    my_brand_path(brand_slug: current_brand.slug, locale: I18n.locale)
  end

  def safe_brand_path
    return brand_path if current_brand.nil?
    brand_path(brand_slug: current_brand.slug, locale: I18n.locale)
  end

  def safe_edit_brand_path
    return edit_brand_path if current_brand.nil?
    edit_brand_path(brand_slug: current_brand.slug, locale: I18n.locale)
  end

  def safe_planning_path
    return planning_path if current_brand.nil?
    planning_path(brand_slug: current_brand.slug, locale: I18n.locale)
  end

  private

  def menu_item_active?(path)
    case path
    when safe_my_brand_path
      # My Brand is active for both /brand, /brand/edit and /my-brand
      current_page?(safe_brand_path) || current_page?(safe_edit_brand_path) || current_page?(safe_my_brand_path)
    else
      current_page?(path)
    end
  end
end
