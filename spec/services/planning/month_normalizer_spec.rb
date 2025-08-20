require 'rails_helper'

RSpec.describe Planning::MonthNormalizer do
  describe '.normalize' do
    context 'with single digit months' do
      it 'zero-pads single digit months' do
        expect(described_class.normalize("2024-8")).to eq("2024-08")
        expect(described_class.normalize("2024-1")).to eq("2024-01")
        expect(described_class.normalize("2024-12")).to eq("2024-12")
      end
    end

    context 'with zero-padded months' do
      it 'removes zero padding for double digit months' do
        expect(described_class.normalize("2024-08")).to eq("2024-8")
        expect(described_class.normalize("2024-01")).to eq("2024-1")
        expect(described_class.normalize("2024-12")).to eq("2024-12")
      end
    end

    context 'with invalid formats' do
      it 'returns original string for invalid formats' do
        expect(described_class.normalize("2024")).to eq("2024")
        expect(described_class.normalize("invalid")).to eq("invalid")
        expect(described_class.normalize("2024-13-01")).to eq("2024-13-01")
      end
    end

    context 'with nil or empty input' do
      it 'returns original value' do
        expect(described_class.normalize(nil)).to be_nil
        expect(described_class.normalize("")).to eq("")
        expect(described_class.normalize("   ")).to eq("   ")
      end
    end

    context 'with edge cases' do
      it 'handles various valid formats correctly' do
        expect(described_class.normalize("2025-9")).to eq("2025-09")
        expect(described_class.normalize("2025-09")).to eq("2025-9")
        expect(described_class.normalize("1999-1")).to eq("1999-01")
      end
    end
  end
end
