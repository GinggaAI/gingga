require 'rails_helper'

RSpec.describe Reels::PresenterService do
  let(:user) { create(:user) }
  let(:reel) { build(:reel) }
  let(:template) { "only_avatars" }

  subject(:service) do
    described_class.new(
      reel: reel,
      template: template,
      current_user: user
    )
  end

  describe '#call' do
    context 'with scene-based template' do
      let(:template) { "only_avatars" }

      before do
        allow(ReelSceneBasedPresenter).to receive(:new).and_return(double)
      end

      it 'returns scene-based presenter and view' do
        result = service.call

        expect(result.success?).to be true
        expect(result.data[:view_template]).to eq("reels/scene_based")
        expect(ReelSceneBasedPresenter).to have_received(:new)
      end
    end

    context 'with narrative template' do
      let(:template) { "narration_over_7_images" }

      before do
        allow(ReelNarrativePresenter).to receive(:new).and_return(double)
      end

      it 'returns narrative presenter and view' do
        result = service.call

        expect(result.success?).to be true
        expect(result.data[:view_template]).to eq("reels/narrative")
        expect(ReelNarrativePresenter).to have_received(:new)
      end
    end

    context 'with unknown template' do
      let(:template) { "unknown_template" }

      it 'returns failure result' do
        result = service.call

        expect(result.success?).to be false
        expect(result.error).to include("Unknown template")
      end
    end
  end
end
