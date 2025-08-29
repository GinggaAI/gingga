class AddStatusToCreasStrategyPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :creas_strategy_plans, :status, :string, default: 'pending'
    add_column :creas_strategy_plans, :error_message, :text
    add_index :creas_strategy_plans, :status
  end
end
