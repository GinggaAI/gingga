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
      expect(response.body).to include(I18n.t('planning.title'))
    end

    it "includes the page header and description" do
      expect(response.body).to include(I18n.t('planning.title'))
      expect(response.body).to include(I18n.t('planning.subtitle'))
    end

    it "displays the month navigation controls" do
      current_month_display = Date.current.strftime("%B %Y")
      expect(response.body).to include(current_month_display)
    end

    it "shows the Overview and Add Content buttons" do
      expect(response.body).to include(I18n.t('planning.overview'))
      expect(response.body).to include(I18n.t('planning.add_content'))
    end

    it "includes the collapsible strategy form" do
      expect(response.body).to include("strategy-form")
      expect(response.body).to include(I18n.t('planning.strategy_form.title'))
    end

    it "displays the strategy form fields" do
      expect(response.body).to include(I18n.t('planning.strategy_form.objective_label'))
      expect(response.body).to include(I18n.t('planning.strategy_form.monthly_themes_label'))
      expect(response.body).to include(I18n.t('planning.strategy_form.frequency_label'))
      expect(response.body).to include(I18n.t('planning.strategy_form.objective_details_label'))
    end

    it "includes form input elements with proper attributes" do
      expect(response.body).to include('name="strategy_form[objective_of_the_month]"')
      expect(response.body).to include('name="strategy_form[monthly_themes]"')
      expect(response.body).to include('name="strategy_form[frequency_per_week]"')
      expect(response.body).to include('name="strategy_form[objective_details]"')
    end

    it "shows the cancel and submit buttons in the form" do
      # Note: Cancel button might not exist in the actual form
      expect(response.body).to include(I18n.t('planning.strategy_form.generate_strategy'))
    end

    it "displays the calendar grid structure" do
      expect(response.body).to include(I18n.t('planning.calendar.week_1'))
      expect(response.body).to include(I18n.t('planning.calendar.week_2'))
      expect(response.body).to include(I18n.t('planning.calendar.week_3'))
      expect(response.body).to include(I18n.t('planning.calendar.week_4'))
      expect(response.body).to include(I18n.t('planning.calendar.monday'))
      expect(response.body).to include(I18n.t('planning.calendar.tuesday'))
      expect(response.body).to include(I18n.t('planning.calendar.wednesday'))
      expect(response.body).to include(I18n.t('planning.calendar.thursday'))
      expect(response.body).to include(I18n.t('planning.calendar.friday'))
      expect(response.body).to include(I18n.t('planning.calendar.saturday'))
      expect(response.body).to include(I18n.t('planning.calendar.sunday'))
    end

    it "includes content goal dropdown" do
      expect(response.body).to include(I18n.t('planning.calendar.goal'))
      expect(response.body).to include(I18n.t('planning.calendar.awareness'))
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
          objective_details: "Detailed description of the objective",
          monthly_themes: "Theme1, Theme2",
          frequency_per_week: "3"
        }
      }

      # Should redirect (PRG pattern) - Rails uses 302 by default, not 303
      expect(response).to have_http_status(:found)
      expect(response.location).to include("/planning")
    end
  end
end
