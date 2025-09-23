class AddSelectedTemplatesToCreasStrategyPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :creas_strategy_plans, :selected_templates, :jsonb
  end
end
