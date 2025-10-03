require 'rails_helper'

RSpec.describe Brands::SelectionService do
  describe '#call' do
    let(:user) { create(:user) }
    let(:brand1) { create(:brand, user: user) }
    let(:brand2) { create(:brand, user: user) }
    let(:other_user_brand) { create(:brand) }

    context 'when valid parameters are provided' do
      it 'successfully switches to the selected brand' do
        # Arrange
        service = described_class.new(user: user, brand_id: brand2.id)

        # Act
        result = service.call

        # Assert
        expect(result[:success]).to be true
        expect(result[:data][:brand]).to eq(brand2)
        expect(result[:error]).to be_nil
        expect(user.reload.current_brand).to eq(brand2)
      end

      it 'updates the user last_brand reference' do
        # Arrange
        user.update(last_brand: brand1)
        service = described_class.new(user: user, brand_id: brand2.id)

        # Act
        result = service.call

        # Assert
        expect(result[:success]).to be true
        expect(user.reload.last_brand).to eq(brand2)
      end
    end

    context 'when user is nil' do
      it 'returns failure result' do
        # Arrange
        service = described_class.new(user: nil, brand_id: brand1.id)

        # Act
        result = service.call

        # Assert
        expect(result[:success]).to be false
        expect(result[:error]).to eq("User is required")
      end
    end

    context 'when brand_id is blank' do
      it 'returns failure result' do
        # Arrange
        service = described_class.new(user: user, brand_id: nil)

        # Act
        result = service.call

        # Assert
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Brand not found or not accessible")
      end
    end

    context 'when brand belongs to another user' do
      it 'returns failure result' do
        # Arrange
        service = described_class.new(user: user, brand_id: other_user_brand.id)

        # Act
        result = service.call

        # Assert
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Brand not found or not accessible")
      end
    end

    context 'when brand_id does not exist' do
      it 'returns failure result' do
        # Arrange
        service = described_class.new(user: user, brand_id: 99999)

        # Act
        result = service.call

        # Assert
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Brand not found or not accessible")
      end
    end

    context 'when user update fails' do
      it 'returns failure result' do
        # Arrange
        service = described_class.new(user: user, brand_id: brand1.id)
        allow(user).to receive(:update_last_brand).and_return(false)

        # Act
        result = service.call

        # Assert
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Failed to update brand selection")
      end
    end

    context 'when an exception occurs' do
      it 'returns failure result with error message' do
        # Arrange
        service = described_class.new(user: user, brand_id: brand1.id)
        allow(user.brands).to receive(:find_by).and_raise(StandardError, "Database error")

        # Act
        result = service.call

        # Assert
        expect(result[:success]).to be false
        expect(result[:error]).to eq("An error occurred: Database error")
      end
    end
  end
end
