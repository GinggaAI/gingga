module Planning
  class StrategyFormatter
    REQUIRED_FIELDS = %i[
      id strategy_name month objective_of_the_month
      frequency_per_week monthly_themes weekly_plan
    ].freeze

    def self.call(strategy_plan)
      new(strategy_plan).call
    end

    def initialize(strategy_plan)
      @strategy_plan = strategy_plan
    end

    def call
      return null_object unless @strategy_plan

      REQUIRED_FIELDS.index_with { |field| @strategy_plan.public_send(field) }
    end

    private

    def null_object
      { error: I18n.t("planning.messages.strategy_not_found") }
    end
  end
end
