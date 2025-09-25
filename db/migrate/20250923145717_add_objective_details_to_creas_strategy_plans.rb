class AddObjectiveDetailsToCreasStrategyPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :creas_strategy_plans, :objective_details, :text
  end
end
