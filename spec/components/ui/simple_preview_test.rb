require "rails_helper"

# Simple test to verify all preview components can be instantiated and their methods called
RSpec.describe "UI Component Previews", type: :component do
  describe "Preview component instantiation and method calls" do
    it "BadgeComponentPreview methods work" do
      preview = Ui::BadgeComponentPreview.new
      expect { preview.default }.not_to raise_error
      expect { preview.variants }.not_to raise_error
      expect { preview.goal_variants }.not_to raise_error
      expect { preview.sizes }.not_to raise_error
    end

    it "ButtonComponentPreview methods work" do
      preview = Ui::ButtonComponentPreview.new
      expect { preview.default }.not_to raise_error
      expect { preview.disabled }.not_to raise_error
      expect { preview.as_link }.not_to raise_error
    end

    it "ChipComponentPreview methods work" do
      preview = Ui::ChipComponentPreview.new
      expect { preview.default }.not_to raise_error
      expect { preview.variants }.not_to raise_error
      expect { preview.removable }.not_to raise_error
      expect { preview.as_link }.not_to raise_error
      expect { preview.content_types }.not_to raise_error
    end

    it "FormSectionComponentPreview methods work" do
      preview = Ui::FormSectionComponentPreview.new
      expect { preview.default }.not_to raise_error
      expect { preview.without_description }.not_to raise_error
    end

    it "PlanningWeekCardComponentPreview methods work" do
      preview = Ui::PlanningWeekCardComponentPreview.new
      expect { preview.draft_week }.not_to raise_error
      expect { preview.scheduled_week }.not_to raise_error
      expect { preview.published_week }.not_to raise_error
      expect { preview.no_goals }.not_to raise_error
      expect { preview.multiple_goals }.not_to raise_error
    end

    it "SceneFieldsComponentPreview methods work" do
      preview = Ui::SceneFieldsComponentPreview.new
      expect { preview.default }.not_to raise_error
      expect { preview.with_data }.not_to raise_error
      expect { preview.removable_scene }.not_to raise_error
    end

    it "ToastComponentPreview methods work" do
      preview = Ui::ToastComponentPreview.new
      expect { preview.success }.not_to raise_error
      expect { preview.warning }.not_to raise_error
      expect { preview.error }.not_to raise_error
      expect { preview.info }.not_to raise_error
      expect { preview.not_dismissible }.not_to raise_error
      expect { preview.no_auto_dismiss }.not_to raise_error
    end

    it "ToggleComponentPreview methods work" do
      preview = Ui::ToggleComponentPreview.new
      expect { preview.default }.not_to raise_error
      expect { preview.checked }.not_to raise_error
      expect { preview.disabled }.not_to raise_error
      expect { preview.without_description }.not_to raise_error
    end
  end

  describe "Preview inheritance" do
    it "all preview classes inherit from ViewComponent::Preview" do
      preview_classes = [
        Ui::BadgeComponentPreview,
        Ui::ButtonComponentPreview,
        Ui::ChipComponentPreview,
        Ui::FormSectionComponentPreview,
        Ui::PlanningWeekCardComponentPreview,
        Ui::SceneFieldsComponentPreview,
        Ui::ToastComponentPreview,
        Ui::ToggleComponentPreview
      ]

      preview_classes.each do |klass|
        expect(klass.superclass).to eq(ViewComponent::Preview)
      end
    end
  end
end
