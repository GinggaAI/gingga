module Ui
  class FormSectionComponentPreview < ViewComponent::Preview
    def default
      render(Ui::FormSectionComponent.new(
        title: "Brand Identity",
        description: "Core information about your brand"
      )) do
        <<~HTML.html_safe
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium mb-2">Brand Name</label>
              <input type="text" placeholder="Enter your brand name" class="w-full px-4 py-3 rounded-lg border">
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">Industry</label>
              <select class="w-full px-4 py-3 rounded-lg border">
                <option>Technology</option>
                <option>Fashion & Beauty</option>
                <option>Food & Beverage</option>
              </select>
            </div>
          </div>
        HTML
      end
    end

    def without_description
      render(Ui::FormSectionComponent.new(
        title: "Contact Information"
      )) do
        <<~HTML.html_safe
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium mb-2">Email</label>
              <input type="email" placeholder="email@example.com" class="w-full px-4 py-3 rounded-lg border">
            </div>
          </div>
        HTML
      end
    end
  end
end
