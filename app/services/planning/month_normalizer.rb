module Planning
  class MonthNormalizer
    MONTH_FORMAT_REGEX = /^\d{4}-\d+$/.freeze

    def self.normalize(month)
      new(month).normalize
    end

    def initialize(month)
      @month = month
    end

    def normalize
      return @month unless valid_format?

      year, month_num = @month.split("-")

      if single_digit_month?(month_num)
        zero_pad_month(year, month_num)
      else
        remove_zero_padding(year, month_num)
      end
    end

    private

    def valid_format?
      @month.present? && @month.match?(MONTH_FORMAT_REGEX)
    end

    def single_digit_month?(month_num)
      month_num.length == 1
    end

    def zero_pad_month(year, month_num)
      "#{year}-#{month_num.rjust(2, '0')}"
    end

    def remove_zero_padding(year, month_num)
      "#{year}-#{month_num.to_i}"
    end
  end
end
