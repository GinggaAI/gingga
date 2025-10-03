require 'rails_helper'

RSpec.describe 'Voxa Content Refinement - No Duplication', type: :integration do
  include ActiveJob::TestHelper

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
                   "title" => "Original Content",
                   "description" => "Original description",
                   "hook" => "Original hook",
                   "platform" => "Instagram",
                   "pilar" => "C"
                 }
               ]
             }
           },
           weekly_plan: [
             {
               "ideas" => [
                 { "id" => "202508-testbrand-w1-i1-C" }
               ]
             }
           ])
  end

  let(:sample_voxa_response) do
    {
      "items" => [
        {
          "id" => "voxa-20250819-w1-i1",  # New Voxa-generated ID
          "origin_id" => "202508-testbrand-w1-i1-C",  # Original ID for matching
          "origin_source" => "content_distribution",
          "week" => 1,
          "content_name" => "Refined Content",
          "status" => "in_production",
          "creation_date" => "2025-08-19",
          "publish_date" => "2025-08-22",
          "content_type" => "reel",
          "platform" => "Instagram",
          "pilar" => "C",
          "template" => "only_avatars",
          "video_source" => "kling",
          "post_description" => "Refined description",
          "text_base" => "Refined text base",
          "hashtags" => "#refined #content",
          "hook" => "Refined hook",
          "cta" => "Refined CTA",
          "kpi_focus" => "engagement",
          "success_criteria" => ">10% saves"
        }
      ]
    }.to_json
  end

  it 'updates existing content items instead of creating duplicates' do
    # Step 1: Create initial draft content items
    content_items = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan).call
    expect(content_items.count).to eq(1)

    original_item = content_items.first
    expect(original_item.content_id).to eq("202508-testbrand-w1-i1-C")
    expect(original_item.status).to eq("draft")
    expect(original_item.content_name).to eq("Original Content (Week 1)")

    # Step 2: Mock OpenAI to return refined content
    mock_chat_client = instance_double(GinggaOpenAI::ChatClient)
    allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
    allow(mock_chat_client).to receive(:chat!).and_return(sample_voxa_response)

    # Step 3: Run Voxa refinement
    expect {
      perform_enqueued_jobs do
        Creas::VoxaContentService.new(strategy_plan: strategy_plan).call
      end
    }.not_to change(CreasContentItem, :count)

    # Step 4: Verify the item was updated, not duplicated
    updated_item = CreasContentItem.find(original_item.id)
    expect(updated_item.content_id).to eq("202508-testbrand-w1-i1-C") # Preserved original content_id
    expect(updated_item.status).to eq("in_production") # Updated status
    expect(updated_item.content_name).to eq("Refined Content") # Updated content
    expect(updated_item.post_description).to eq("Refined description")
    expect(updated_item.hashtags).to eq("#refined #content")

    # Step 5: Verify no duplicates exist
    expect(CreasContentItem.where(content_id: "202508-testbrand-w1-i1-C").count).to eq(1)
    expect(CreasContentItem.where(content_id: "voxa-20250819-w1-i1").count).to eq(0)
  end

  it 'creates new items when no existing match is found' do
    # First create initial draft content so ContentItemInitializerService doesn't create new ones
    create(:creas_content_item,
           creas_strategy_plan: strategy_plan,
           user: user,
           brand: brand,
           content_id: "202508-testbrand-w1-i1-C",
           content_name: "Initial Content",
           status: "draft")

    # Mock OpenAI to return content with no origin_id match
    different_voxa_response = {
      "items" => [ {
        "id" => "voxa-new-item",
        "origin_id" => "nonexistent-origin-id",
        "week" => 1,
        "content_name" => "New Content",
        "status" => "in_production",
        "creation_date" => "2025-08-19",
        "publish_date" => "2025-08-22",
        "content_type" => "reel",
        "platform" => "Instagram",
        "pilar" => "C",
        "template" => "only_avatars",
        "video_source" => "kling",
        "post_description" => "New description",
        "text_base" => "New text",
        "hashtags" => "#new #content"
      } ]
    }.to_json

    mock_chat_client = instance_double(GinggaOpenAI::ChatClient)
    allow(GinggaOpenAI::ChatClient).to receive(:new).and_return(mock_chat_client)
    allow(mock_chat_client).to receive(:chat!).and_return(different_voxa_response)

    expect {
      perform_enqueued_jobs do
        Creas::VoxaContentService.new(strategy_plan: strategy_plan).call
      end
    }.to change(CreasContentItem, :count).by(1)

    new_item = CreasContentItem.find_by(content_id: "voxa-new-item")
    expect(new_item).to be_present
    expect(new_item.content_id).to eq("voxa-new-item")
    expect(new_item.origin_id).to eq("nonexistent-origin-id")
    expect(new_item.content_name).to eq("New Content")
  end
end
