require 'rails_helper'

RSpec.describe Planning::MonthResolver do
  describe '#call' do
    context 'with valid month parameter' do
      it 'returns the provided month' do
        resolver = described_class.new('2024-12')
        result = resolver.call

        expect(result.month).to eq('2024-12')
        expect(result.display_month).to eq('December 2024')
      end
    end

    context 'with invalid month parameter' do
      it 'returns nil for security' do
        resolver = described_class.new('invalid')
        result = resolver.call

        expect(result.month).to be_nil
        expect(result.display_month).to eq('Invalid Month')
      end
    end

    context 'without month parameter' do
      it 'returns current month' do
        resolver = described_class.new
        result = resolver.call

        expect(result.month).to eq(Date.current.strftime("%Y-%-m"))
      end
    end

    context 'with malformed date' do
      it 'handles errors gracefully' do
        resolver = described_class.new('2024-13') # Invalid month
        result = resolver.call

        expect(result.month).to be_nil
        expect(result.display_month).to eq("Invalid Month")
      end
    end
  end
end
