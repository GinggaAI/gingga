require 'rails_helper'

RSpec.describe "Planning UI Components", type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    sign_in user, scope: :user
  end

  describe "Planning Page UI Elements" do
    before do
      get planning_path
    end

    it "renders the main planning interface" do
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Smart Planning")
    end

    it "includes the page header and description" do
      expect(response.body).to include("Smart Planning")
      expect(response.body).to include("Plan your content strategy with AI-powered insights")
    end

    it "displays the month navigation controls" do
      expect(response.body).to include("August 2025")
    end

    it "shows the Overview and Add Content buttons" do
      expect(response.body).to include("Overview")
      expect(response.body).to include("Add Content")
    end

    it "includes the collapsible strategy form" do
      expect(response.body).to include("strategy-form")
      expect(response.body).to include("🧠 Generate New Content Strategy")
    end

    it "displays the strategy form fields" do
      expect(response.body).to include("Objective of the Month")
      expect(response.body).to include("Monthly Themes")
      expect(response.body).to include("Frequency per Week")
      expect(response.body).to include("Resources Override")
    end

    it "includes form input elements with proper attributes" do
      expect(response.body).to include('name="strategy_form[objective_of_the_month]"')
      expect(response.body).to include('name="strategy_form[monthly_themes]"')
      expect(response.body).to include('name="strategy_form[frequency_per_week]"')
      expect(response.body).to include('name="strategy_form[resources_override]"')
    end

    it "shows the cancel and submit buttons in the form" do
      expect(response.body).to include("Cancel")
      expect(response.body).to include("Generate Strategy")
    end

    it "displays the calendar grid structure" do
      expect(response.body).to include("Week 1")
      expect(response.body).to include("Week 2")
      expect(response.body).to include("Week 3")
      expect(response.body).to include("Week 4")
      expect(response.body).to include("Mon")
      expect(response.body).to include("Tue")
      expect(response.body).to include("Wed")
      expect(response.body).to include("Thu")
      expect(response.body).to include("Fri")
      expect(response.body).to include("Sat")
      expect(response.body).to include("Sun")
    end

    it "includes content goal dropdown" do
      expect(response.body).to include("Goal:")
      expect(response.body).to include("Awareness")
    end

    it "includes proper form submission setup" do
      expect(response.body).to include('method="post"')
      expect(response.body).to include('authenticity_token')
    end
  end

  describe "Form Behavior" do
    it "POST request creates form submission" do
      post creas_strategist_index_path, params: {
        month: "2025-08",
        strategy_form: {
          objective_of_the_month: "Test objective",
          monthly_themes: "Theme1, Theme2",
          frequency_per_week: "3",
          resources_override: "{}"
        }
      }

      # Should redirect (PRG pattern) - Rails uses 302 by default, not 303
      expect(response).to have_http_status(:found)
      expect(response.location).to include("/planning")
    end
  end
end
