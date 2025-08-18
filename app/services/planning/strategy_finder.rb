module Planning
  class StrategyFinder
    def self.find_for_brand_and_month(brand, month)
      new(brand, month).find
    end

    def initialize(brand, month)
      @brand = brand
      @month = month
    end

    def find
      return nil unless @brand&.persisted?

      find_exact_match || find_normalized_match
    end

    private

    def find_exact_match
      @brand.creas_strategy_plans
             .where(month: @month)
             .order(created_at: :desc)
             .first
    end

    def find_normalized_match
      return nil unless normalized_month

      @brand.creas_strategy_plans
             .where(month: normalized_month)
             .order(created_at: :desc)
             .first
    end

    def normalized_month
      @normalized_month ||= MonthNormalizer.normalize(@month)
    end
  end
end
