require 'rails_helper'

RSpec.describe Planning::MonthFormatter do
  describe '.format_for_display' do
    it 'formats valid month string correctly' do
      result = described_class.format_for_display('2024-1')

      expect(result).to eq('January 2024')
    end

    it 'formats valid month string with double digit month correctly' do
      result = described_class.format_for_display('2024-12')

      expect(result).to eq('December 2024')
    end

    it 'returns fallback text for nil month string' do
      result = described_class.format_for_display(nil)

      expect(result).to eq('Current Month')
    end

    it 'returns fallback text for empty month string' do
      result = described_class.format_for_display('')

      expect(result).to eq('Current Month')
    end

    it 'returns original string for invalid month format' do
      result = described_class.format_for_display('invalid-format')

      expect(result).to eq('invalid-format')
    end

    it 'returns original string for invalid month number' do
      result = described_class.format_for_display('2024-13')

      expect(result).to eq('2024-13')
    end

    it 'returns formatted string for invalid year (converts to 0)' do
      result = described_class.format_for_display('invalid-1')

      expect(result).to eq('January 0000')
    end

    it 'logs warning for invalid month format' do
      expect(Rails.logger).to receive(:warn)
        .with(/MonthFormatter: Failed to format month 'invalid-format'/)

      described_class.format_for_display('invalid-format')
    end

    it 'logs warning for invalid month number' do
      expect(Rails.logger).to receive(:warn)
        .with(/MonthFormatter: Failed to format month '2024-13'/)

      described_class.format_for_display('2024-13')
    end

    it 'does not log warning for invalid year that converts to valid date' do
      expect(Rails.logger).not_to receive(:warn)

      described_class.format_for_display('invalid-1')
    end
  end

  describe '#initialize' do
    it 'sets month_string instance variable' do
      formatter = described_class.new('2024-1')

      expect(formatter.instance_variable_get(:@month_string)).to eq('2024-1')
    end
  end

  describe '#format_for_display' do
    context 'when month_string is present' do
      it 'calls parse_and_format' do
        formatter = described_class.new('2024-1')
        expect(formatter).to receive(:parse_and_format).and_return('January 2024')

        result = formatter.format_for_display

        expect(result).to eq('January 2024')
      end
    end

    context 'when month_string is not present' do
      it 'returns fallback text without calling parse_and_format' do
        formatter = described_class.new(nil)
        expect(formatter).not_to receive(:parse_and_format)

        result = formatter.format_for_display

        expect(result).to eq('Current Month')
      end
    end

    context 'when parse_and_format raises an error' do
      it 'handles ArgumentError and returns original string' do
        formatter = described_class.new('invalid')
        allow(formatter).to receive(:parse_and_format).and_raise(ArgumentError, 'Invalid date')
        allow(Rails.logger).to receive(:warn)

        result = formatter.format_for_display

        expect(result).to eq('invalid')
      end

      it 'handles NoMethodError and returns original string' do
        formatter = described_class.new('invalid')
        allow(formatter).to receive(:parse_and_format).and_raise(NoMethodError, 'undefined method')
        allow(Rails.logger).to receive(:warn)

        result = formatter.format_for_display

        expect(result).to eq('invalid')
      end
    end
  end

  describe 'FALLBACK_TEXT' do
    it 'is defined as frozen string' do
      expect(Planning::MonthFormatter::FALLBACK_TEXT).to eq('Current Month')
      expect(Planning::MonthFormatter::FALLBACK_TEXT).to be_frozen
    end
  end
end
