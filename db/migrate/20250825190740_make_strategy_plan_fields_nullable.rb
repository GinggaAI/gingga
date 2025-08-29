class MakeStrategyPlanFieldsNullable < ActiveRecord::Migration[8.0]
  def up
    change_column_null :creas_strategy_plans, :objective_of_the_month, true
    change_column_null :creas_strategy_plans, :frequency_per_week, true
  end

  def down
    # Note: This down migration might fail if there are records with null values
    change_column_null :creas_strategy_plans, :objective_of_the_month, false
    change_column_null :creas_strategy_plans, :frequency_per_week, false
  end
end
