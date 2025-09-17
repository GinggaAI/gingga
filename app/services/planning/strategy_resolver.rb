module Planning
  class StrategyResolver
    def initialize(brand:, month:, plan_id: nil)
      @brand = brand
      @month = month
      @plan_id = plan_id
    end

    def call
      return nil unless @brand

      if @plan_id.present?
        find_by_id
      else
        return nil if @month.nil? # Return nil for invalid months when finding by month
        find_by_month
      end
    end

    private

    attr_reader :brand, :month, :plan_id

    def find_by_id
      @brand.creas_strategy_plans.find_by(id: @plan_id)
    end

    def find_by_month
      StrategyFinder.find_for_brand_and_month(@brand, @month)
    end
  end
end
