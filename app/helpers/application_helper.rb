module ApplicationHelper
  def menu_item_style(path)
    menu_item_active?(path) ? "color: #000000;" : "color: rgba(255,255,255,0.7);"
  end

  def menu_item_class(path)
    menu_item_active?(path) ? "active" : ""
  end

  private

  def menu_item_active?(path)
    case path
    when my_brand_path
      # My Brand is active for both /brand, /brand/edit and /my-brand
      current_page?(brand_path) || current_page?(edit_brand_path) || current_page?(my_brand_path)
    else
      current_page?(path)
    end
  end
end
