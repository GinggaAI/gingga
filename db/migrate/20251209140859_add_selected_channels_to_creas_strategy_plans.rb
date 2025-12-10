class AddSelectedChannelsToCreasStrategyPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :creas_strategy_plans, :selected_channels, :jsonb, default: ["instagram"], null: false

    add_index :creas_strategy_plans, :selected_channels, using: :gin

    change_column_comment :creas_strategy_plans, :selected_channels,
      "Array of selected social media channels (e.g., ['instagram', 'tiktok']). Defaults to ['instagram']."
  end
end
