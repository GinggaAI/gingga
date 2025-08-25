require 'rails_helper'

RSpec.describe 'Day of Week Content Placement', type: :integration do
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:strategy_plan) do
    create(:creas_strategy_plan,
           user: user,
           brand: brand,
           content_distribution: {
             "C" => {
               "ideas" => [
                 {
                   "id" => "202508-testbrand-w1-i1-C",
                   "title" => "Monday Content",
                   "description" => "Educational content",
                   "platform" => "Instagram",
                   "pilar" => "C",
                   "suggested_day" => "Monday"
                 },
                 {
                   "id" => "202508-testbrand-w1-i2-C",
                   "title" => "Wednesday Content",
                   "description" => "More educational content",
                   "platform" => "Instagram",
                   "pilar" => "C",
                   "suggested_day" => "Wednesday"
                 }
               ]
             },
             "E" => {
               "ideas" => [
                 {
                   "id" => "202508-testbrand-w1-i1-E",
                   "title" => "Friday Fun",
                   "description" => "Entertainment content",
                   "platform" => "Instagram",
                   "pilar" => "E"
                   # No suggested_day - should default to strategic placement
                 }
               ]
             }
           })
  end

  it 'creates content items with proper day_of_the_week assignments' do
    # Step 1: Initialize content items from strategy
    content_items = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call

    expect(content_items.length).to eq(3)

    # Step 2: Verify explicit day assignments are respected
    monday_item = content_items.find { |item| item.content_id == "202508-testbrand-w1-i1-C" }
    expect(monday_item.day_of_the_week).to eq("Monday")

    wednesday_item = content_items.find { |item| item.content_id == "202508-testbrand-w1-i2-C" }
    expect(wednesday_item.day_of_the_week).to eq("Wednesday")

    # Step 3: Verify strategic assignment for entertainment content (E pilar)
    entertainment_item = content_items.find { |item| item.content_id == "202508-testbrand-w1-i1-E" }
    expect(entertainment_item.day_of_the_week).to be_in([ "Monday", "Friday", "Saturday" ])
    expect(entertainment_item.pilar).to eq("E")
  end

  it 'ensures content appears on correct calendar days in frontend' do
    # Step 1: Create content items
    content_items = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call

    # Step 2: Verify presenter includes day_of_the_week in JSON
    presenter = PlanningPresenter.new({}, current_plan: strategy_plan)
    plan_json = JSON.parse(presenter.current_plan_json)

    content_items_json = plan_json["content_items"]
    expect(content_items_json).to be_present
    expect(content_items_json.length).to eq(3)

    # Step 3: Verify each content item has day_of_the_week
    content_items_json.each do |item|
      expect(item["day_of_the_week"]).to be_present
      expect(%w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]).to include(item["day_of_the_week"])
    end

    # Step 4: Verify specific day assignments
    monday_json = content_items_json.find { |item| item["id"] == "202508-testbrand-w1-i1-C" }
    expect(monday_json["day_of_the_week"]).to eq("Monday")

    wednesday_json = content_items_json.find { |item| item["id"] == "202508-testbrand-w1-i2-C" }
    expect(wednesday_json["day_of_the_week"]).to eq("Wednesday")
  end

  it 'provides easy querying by day of the week' do
    # Create content items
    content_items = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call

    # Test the scope functionality - filter by strategy plan to isolate test data
    monday_items = strategy_plan.creas_content_items.by_day_of_week("Monday")
    wednesday_items = strategy_plan.creas_content_items.by_day_of_week("Wednesday")

    expect(monday_items.count).to eq(1)
    expect(monday_items.first.content_name).to eq("Monday Content")

    expect(wednesday_items.count).to eq(1)
    expect(wednesday_items.first.content_name).to eq("Wednesday Content")

    # Test combined scopes
    week1_monday_items = strategy_plan.creas_content_items.by_week(1).by_day_of_week("Monday")
    expect(week1_monday_items.count).to eq(1)
  end

  describe 'Voxa refinement preserves day assignments' do
    let(:sample_voxa_response) do
      {
        "items" => [
          {
            "id" => "voxa-refined-123",
            "origin_id" => "202508-testbrand-w1-i1-C",
            "week" => 1,
            "content_name" => "Refined Monday Content",
            "status" => "in_production",
            "creation_date" => "2025-08-26",
            "publish_date" => "2025-08-26",
            "content_type" => "reel",
            "platform" => "Instagram",
            "pilar" => "C",
            "template" => "solo_avatars",
            "video_source" => "kling",
            "post_description" => "Refined description",
            "text_base" => "Refined text",
            "hashtags" => "#refined #monday",
            "day_of_the_week" => "Monday"  # Explicit from Voxa
          }
        ]
      }.to_json
    end

    it 'updates existing items while preserving day_of_the_week' do
      # Step 1: Create initial content
      initial_items = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call
      monday_item = initial_items.find { |item| item.content_id == "202508-testbrand-w1-i1-C" }
      expect(monday_item.day_of_the_week).to eq("Monday")
      expect(monday_item.status).to eq("draft")

      # Step 2: Mock Voxa refinement
      mock_chat_client = instance_double(GinggaOpenAI::ChatClient)
      allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
      allow(mock_chat_client).to receive(:chat!).and_return(sample_voxa_response)

      # Step 3: Run Voxa refinement
      expect {
        Creas::VoxaContentService.new(strategy_plan: strategy_plan).call
      }.not_to change(CreasContentItem, :count)

      # Step 4: Verify day assignment preserved during update
      refined_item = CreasContentItem.find(monday_item.id)
      expect(refined_item.day_of_the_week).to eq("Monday")
      expect(refined_item.status).to eq("in_production")
      expect(refined_item.content_name).to eq("Refined Monday Content")
      expect(refined_item.content_id).to eq("202508-testbrand-w1-i1-C")  # Preserved original ID
    end
  end
end
