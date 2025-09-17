require 'rails_helper'
require 'ostruct'

RSpec.describe Reels::SmartPlanningPreloadService do
  let(:user) { create(:user) }
  let(:reel) { create(:reel, user: user) }
  let(:planning_data) do
    {
      "title" => "Test Reel Title",
      "description" => "Test description",
      "shotplan" => {
        "scenes" => [
          { "voiceover" => "First scene script" },
          { "voiceover" => "Second scene script" }
        ]
      }
    }.to_json
  end

  subject(:service) do
    described_class.new(
      reel: reel,
      planning_data: planning_data,
      current_user: user
    )
  end

  describe '#call' do
    context 'with valid planning data' do
      before do
        allow(Reels::ScenesPreloadService).to receive(:new).and_return(
          double(call: OpenStruct.new(success?: true, data: { created_scenes: 2, total_scenes: 2 }))
        )
      end

      it 'updates reel info and preloads scenes' do
        expect { service.call }.to change { reel.reload.title }.to("Test Reel Title")
        expect(Reels::ScenesPreloadService).to have_received(:new)
      end

      it 'returns successful result' do
        result = service.call
        expect(result.success?).to be true
      end
    end

    context 'with invalid JSON' do
      let(:planning_data) { "invalid json" }

      it 'returns failure result' do
        result = service.call
        expect(result.success?).to be false
        expect(result.error).to eq("Invalid planning data format")
      end
    end

    context 'without shotplan scenes' do
      let(:planning_data) { '{"title": "Test Title"}' }

      it 'only updates reel info' do
        expect { service.call }.to change { reel.reload.title }.to("Test Title")
        expect(Reels::ScenesPreloadService).not_to receive(:new)
      end
    end

    context 'with hash planning data (already parsed)' do
      let(:planning_data) do
        {
          "title" => "Hash Title",
          "description" => "Hash description",
          "shotplan" => {
            "scenes" => [ { "voiceover" => "Scene from hash" } ]
          }
        }
      end

      before do
        allow(Reels::ScenesPreloadService).to receive(:new).and_return(
          double(call: OpenStruct.new(success?: true, data: { created_scenes: 1, total_scenes: 1 }))
        )
      end

      it 'processes hash data without parsing' do
        expect { service.call }.to change { reel.reload.title }.to("Hash Title")
        expect(result = service.call).to be_success
      end
    end

    context 'with alternative field names' do
      let(:planning_data) do
        {
          "content_name" => "Alternative Title",
          "post_description" => "Alternative description"
        }.to_json
      end

      it 'uses alternative field names for title and description' do
        result = service.call

        reel.reload
        expect(reel.title).to eq("Alternative Title")
        expect(reel.description).to eq("Alternative description")
        expect(result.success?).to be true
      end
    end

    context 'when scene preload fails' do
      let(:planning_data) do
        {
          "title" => "Test Title",
          "shotplan" => {
            "scenes" => [ { "voiceover" => "Scene content" } ]
          }
        }.to_json
      end

      before do
        allow(Reels::ScenesPreloadService).to receive(:new).and_return(
          double(call: OpenStruct.new(success?: false, error: "Scene creation failed"))
        )
      end

      it 'continues with reel update despite scene failure' do
        expect(Rails.logger).to receive(:warn).with(/Scene preload had issues/)

        result = service.call
        reel.reload

        expect(reel.title).to eq("Test Title")
        expect(result.success?).to be true
      end
    end

    context 'when reel update fails' do
      before do
        allow(reel).to receive(:update).and_return(false)
        allow(reel).to receive(:errors).and_return(double(full_messages: [ "Title is invalid" ]))
        allow(reel).to receive(:template).and_return("avatar_only")

        # Mock the reel_scenes association properly
        scenes_association = double('ReeScene association')
        allow(scenes_association).to receive(:count).and_return(0)
        allow(scenes_association).to receive(:delete_all)
        allow(scenes_association).to receive(:reset)
        allow(reel).to receive(:reel_scenes).and_return(scenes_association)

        # Skip scene preloading for this test
        allow(service).to receive(:shotplan_scenes_available?).and_return(false)
      end

      it 'continues execution despite update failure' do
        result = service.call
        expect(result.success?).to be true
      end
    end

    context 'with empty shotplan scenes' do
      let(:planning_data) do
        {
          "title" => "Test Title",
          "shotplan" => { "scenes" => [] }
        }.to_json
      end

      it 'skips scene creation for empty scenes array' do
        expect(Reels::ScenesPreloadService).not_to receive(:new)

        result = service.call
        expect(result.success?).to be true
      end
    end

    context 'when service raises an exception' do
      before do
        allow(service).to receive(:parse_planning_data).and_raise(StandardError, "Unexpected error")
      end

      it 'handles the exception and returns failure result' do
        expect(Rails.logger).to receive(:error).with(/Failed to preload smart planning data/)
        expect(Rails.logger).to receive(:error).with(/Backtrace:/)

        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include("Preload failed: Unexpected error")
      end
    end
  end
end
