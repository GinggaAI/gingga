require 'rails_helper'

RSpec.describe "Planning Security", type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }

  before do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password123'
      }
    }
  end

  describe "XSS Protection" do
    context "when month parameter contains malicious JavaScript" do
      let(:malicious_month) { "2025-08'; alert('xss'); //" }

      it "does not execute the malicious script" do
        get planning_path(month: malicious_month)

        expect(response).to have_http_status(:success)
        # The malicious script should NOT appear in the response
        expect(response.body).not_to include("alert('xss')")
        # JavaScript is now moved to external files, so we check for the comment instead
        expect(response.body).to include("JavaScript moved to app/javascript/controllers/planning_controller.js")
      end

      it "displays safe fallback text in the month display" do
        get planning_path(month: malicious_month)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Invalid Month")
      end
    end

    context "when month parameter contains HTML tags" do
      let(:malicious_month) { "<script>alert('xss')</script>" }

      it "neutralizes the malicious input" do
        get planning_path(month: malicious_month)

        expect(response).to have_http_status(:success)
        # Should not execute the script
        expect(response.body).not_to include("<script>alert('xss')</script>")
        expect(response.body).to include("Invalid Month")
      end
    end

    context "with valid month parameter" do
      it "properly displays the month" do
        get planning_path(month: "2025-08")

        expect(response).to have_http_status(:success)
        expect(response.body).to include("August 2025")
        # JavaScript is now in external files with Stimulus data values
        expect(response.body).to include('data-planning-current-month-value')
      end
    end
  end
end
