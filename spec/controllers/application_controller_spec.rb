require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  let(:user) { create(:user) }

  before { sign_in user, scope: :user }

  describe '#current_brand' do
    context 'when user has no brands' do
      it 'returns nil' do
        expect(controller.send(:current_brand)).to be_nil
      end
    end

    context 'when user has brands but no last_brand set' do
      let!(:first_brand) { create(:brand, user: user, name: 'First Brand') }
      let!(:second_brand) { create(:brand, user: user, name: 'Second Brand') }

      it 'returns the first brand (default behavior)' do
        # Using user.current_brand to test the actual logic
        expect(controller.send(:current_brand)).to eq(user.brands.first)
      end
    end

    context 'when user has a specific last_brand set' do
      let!(:first_brand) { create(:brand, user: user, name: 'First Brand') }
      let!(:second_brand) { create(:brand, user: user, name: 'Second Brand') }

      before { user.update!(last_brand: second_brand) }

      it 'returns the last_brand' do
        expect(controller.send(:current_brand)).to eq(second_brand)
      end
    end

    context 'when user is not signed in' do
      it 'returns nil' do
        # Simulate not being signed in by stubbing current_user to return nil
        allow(controller).to receive(:current_user).and_return(nil)
        expect(controller.send(:current_brand)).to be_nil
      end
    end
  end

  describe 'helper_method :current_brand' do
    it 'makes current_brand available to views' do
      expect(controller.class._helper_methods).to include(:current_brand)
    end
  end
end
