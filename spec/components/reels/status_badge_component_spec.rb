# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reels::StatusBadgeComponent, type: :component do
  describe "#css_classes" do
    it "returns correct classes for draft status" do
      component = described_class.new(status: "draft")
      expect(component.css_classes).to eq(%w[status-badge status-badge--draft])
    end

    it "returns correct classes for processing status" do
      component = described_class.new(status: "processing")
      expect(component.css_classes).to eq(%w[status-badge status-badge--processing])
    end

    it "returns correct classes for completed status" do
      component = described_class.new(status: "completed")
      expect(component.css_classes).to eq(%w[status-badge status-badge--completed])
    end

    it "returns correct classes for failed status" do
      component = described_class.new(status: "failed")
      expect(component.css_classes).to eq(%w[status-badge status-badge--failed])
    end

    it "returns draft classes as fallback for unknown status" do
      component = described_class.new(status: "unknown")
      expect(component.css_classes).to eq(%w[status-badge status-badge--draft])
    end

    it "strips whitespace from status" do
      component = described_class.new(status: "  completed  ")
      expect(component.css_classes).to eq(%w[status-badge status-badge--completed])
    end
  end

  describe "rendering" do
    it "renders the status badge with correct classes" do
      render_inline(described_class.new(status: "completed", icon: "✓"))

      expect(page).to have_css("div.status-badge.status-badge--completed")
      expect(page).to have_content("✓")
    end

    it "renders without icon when not provided" do
      render_inline(described_class.new(status: "draft"))

      expect(page).to have_css("div.status-badge.status-badge--draft")
    end

    it "prevents XSS by using whitelisted classes only" do
      # Attempt to inject malicious code
      render_inline(described_class.new(status: "<script>alert('xss')</script>", icon: "X"))

      # Should fall back to safe draft classes
      expect(page).to have_css("div.status-badge.status-badge--draft")
      # Malicious script should not be in class attribute
      expect(page).not_to have_css("div[class*='script']")
    end
  end

  describe "security" do
    it "only uses whitelisted CSS classes" do
      # All possible status values should be whitelisted
      %w[draft processing completed failed].each do |status|
        component = described_class.new(status: status)
        classes = component.css_classes

        expect(classes).to be_an(Array)
        expect(classes).to all(be_a(String))
        expect(classes.first).to eq("status-badge")
      end
    end

    it "does not allow arbitrary class injection" do
      malicious_statuses = [
        "draft onclick=alert(1)",
        "completed'; DROP TABLE users;--",
        "../../../etc/passwd",
        "processing<img src=x onerror=alert(1)>"
      ]

      malicious_statuses.each do |malicious_status|
        component = described_class.new(status: malicious_status)
        # Should always fall back to safe whitelisted classes
        expect(component.css_classes).to eq(%w[status-badge status-badge--draft])
      end
    end
  end
end
