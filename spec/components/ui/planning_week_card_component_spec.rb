require "rails_helper"

RSpec.describe Ui::PlanningWeekCardComponent, type: :component do
  let(:week_number) { 42 }
  let(:start_date) { Date.new(2024, 10, 14) }
  let(:end_date) { Date.new(2024, 10, 20) }
  let(:content_count) { 5 }
  let(:goals) { [ :growth, :engagement ] }
  let(:status) { :scheduled }

  describe "#initialize" do
    it "sets all attributes with provided values" do
      component = described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: end_date,
        content_count: content_count,
        goals: goals,
        status: status
      )

      expect(component.week_number).to eq(week_number)
      expect(component.start_date).to eq(start_date)
      expect(component.end_date).to eq(end_date)
      expect(component.content_count).to eq(content_count)
      expect(component.goals).to eq(goals)
      expect(component.status).to eq(status)
    end

    it "sets default values" do
      component = described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: end_date
      )

      expect(component.content_count).to eq(0)
      expect(component.goals).to eq([])
      expect(component.status).to eq(:draft)
    end

    it "converts goals to array if not already" do
      component = described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: end_date,
        goals: :growth
      )

      expect(component.goals).to eq([ :growth ])
    end

    it "validates status and falls back to draft for invalid status" do
      component = described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: end_date,
        status: :invalid
      )

      expect(component.status).to eq(:draft)
    end

    it "accepts string status and converts to symbol" do
      component = described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: end_date,
        status: "published"
      )

      expect(component.status).to eq(:published)
    end
  end

  describe "#call" do
    let(:component) do
      described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: end_date,
        content_count: content_count,
        goals: goals,
        status: status
      )
    end

    it "renders a div with correct CSS classes" do
      result = render_inline(component)
      expect(result).to have_css("div.ui-planning-week-card.ui-planning-week-card--scheduled")
    end

    it "renders the header section" do
      result = render_inline(component)
      expect(result).to have_css("header.ui-planning-week-card__header")
      expect(result).to have_css("h4.ui-planning-week-card__title", text: "Week 42")
      expect(result).to have_css("p.ui-planning-week-card__date", text: "Oct 14 - Oct 20")
    end

    it "renders the metrics section" do
      result = render_inline(component)
      expect(result).to have_css("div.ui-planning-week-card__metrics")
      expect(result).to have_css("span.ui-planning-week-card__metric-value", text: "5")
      expect(result).to have_css("span.ui-planning-week-card__metric-label", text: "pieces")
    end

    it "renders goals when present" do
      result = render_inline(component)
      expect(result).to have_css("div.ui-planning-week-card__goals")
      # Goals should render as badge components
      expect(result).to have_css("span.ui-badge--goal_growth", text: "Growth")
      expect(result).to have_css("span.ui-badge--goal_engagement", text: "Engagement")
    end

    it "does not render goals section when no goals" do
      component_without_goals = described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: end_date,
        goals: []
      )

      result = render_inline(component_without_goals)
      expect(result).not_to have_css("div.ui-planning-week-card__goals")
    end

    it "renders actions section" do
      result = render_inline(component)
      expect(result).to have_css("div.ui-planning-week-card__actions")
    end

    it "renders status badge" do
      result = render_inline(component)
      expect(result).to have_css("span.ui-badge--primary", text: "Scheduled")
    end
  end

  describe "date handling" do
    it "formats date range correctly" do
      component = described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: end_date
      )

      expect(component.send(:date_range)).to eq("Oct 14 - Oct 20")
    end

    it "handles missing dates" do
      component = described_class.new(
        week_number: week_number,
        start_date: nil,
        end_date: nil
      )

      expect(component.send(:date_range)).to eq("No dates set")

      result = render_inline(component)
      expect(result).to have_css("p.ui-planning-week-card__date", text: "No dates set")
    end

    it "handles partial dates" do
      component = described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: nil
      )

      expect(component.send(:date_range)).to eq("No dates set")
    end
  end

  describe "content count pluralization" do
    it "uses singular for count of 1" do
      component = described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: end_date,
        content_count: 1
      )

      result = render_inline(component)
      expect(result).to have_css("span.ui-planning-week-card__metric-label", text: "piece")
    end

    it "uses plural for count of 0" do
      component = described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: end_date,
        content_count: 0
      )

      result = render_inline(component)
      expect(result).to have_css("span.ui-planning-week-card__metric-label", text: "pieces")
    end

    it "uses plural for count greater than 1" do
      component = described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: end_date,
        content_count: 3
      )

      result = render_inline(component)
      expect(result).to have_css("span.ui-planning-week-card__metric-label", text: "pieces")
    end
  end

  describe "status-specific rendering" do
    context "when status is draft" do
      let(:draft_component) do
        described_class.new(
          week_number: week_number,
          start_date: start_date,
          end_date: end_date,
          status: :draft
        )
      end

      it "renders draft-specific CSS class" do
        result = render_inline(draft_component)
        expect(result).to have_css("div.ui-planning-week-card--draft")
      end

      it "renders warning status badge" do
        result = render_inline(draft_component)
        expect(result).to have_css("span.ui-badge--warning", text: "Draft")
      end

      it "renders Plan Week button" do
        result = render_inline(draft_component)
        expect(result).to have_css("button.ui-button--primary", text: "Plan Week")
      end
    end

    context "when status is scheduled" do
      let(:scheduled_component) do
        described_class.new(
          week_number: week_number,
          start_date: start_date,
          end_date: end_date,
          status: :scheduled
        )
      end

      it "renders scheduled-specific CSS class" do
        result = render_inline(scheduled_component)
        expect(result).to have_css("div.ui-planning-week-card--scheduled")
      end

      it "renders primary status badge" do
        result = render_inline(scheduled_component)
        expect(result).to have_css("span.ui-badge--primary", text: "Scheduled")
      end

      it "renders Edit Plan button" do
        result = render_inline(scheduled_component)
        expect(result).to have_css("button.ui-button--ghost", text: "Edit Plan")
      end
    end

    context "when status is published" do
      let(:published_component) do
        described_class.new(
          week_number: week_number,
          start_date: start_date,
          end_date: end_date,
          status: :published
        )
      end

      it "renders published-specific CSS class" do
        result = render_inline(published_component)
        expect(result).to have_css("div.ui-planning-week-card--published")
      end

      it "renders success status badge" do
        result = render_inline(published_component)
        expect(result).to have_css("span.ui-badge--success", text: "Published")
      end

      it "renders View Results button" do
        result = render_inline(published_component)
        expect(result).to have_css("button.ui-button--secondary", text: "View Results")
      end
    end
  end

  describe "constants" do
    it "defines valid statuses" do
      expected_statuses = %i[draft scheduled published]
      expect(described_class::STATUSES).to eq(expected_statuses)
    end
  end

  describe "private methods" do
    let(:component) do
      described_class.new(
        week_number: week_number,
        start_date: start_date,
        end_date: end_date
      )
    end

    describe "#validate_status" do
      it "returns valid statuses as symbols" do
        described_class::STATUSES.each do |status|
          result = component.send(:validate_status, status)
          expect(result).to eq(status)
        end
      end

      it "returns :draft for invalid statuses" do
        result = component.send(:validate_status, :invalid)
        expect(result).to eq(:draft)
      end

      it "converts string statuses to symbols" do
        result = component.send(:validate_status, "scheduled")
        expect(result).to eq(:scheduled)
      end
    end

    describe "#pluralize_content" do
      it "returns 'piece' for 1" do
        expect(component.send(:pluralize_content, 1)).to eq("piece")
      end

      it "returns 'pieces' for 0" do
        expect(component.send(:pluralize_content, 0)).to eq("pieces")
      end

      it "returns 'pieces' for numbers greater than 1" do
        expect(component.send(:pluralize_content, 5)).to eq("pieces")
        expect(component.send(:pluralize_content, 100)).to eq("pieces")
      end
    end
  end

  describe "all statuses" do
    described_class::STATUSES.each do |status|
      it "renders #{status} status correctly" do
        component = described_class.new(
          week_number: week_number,
          start_date: start_date,
          end_date: end_date,
          status: status
        )

        result = render_inline(component)
        expect(result).to have_css("div.ui-planning-week-card--#{status}")
      end
    end
  end
end
