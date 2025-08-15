class CreateCreasStrategyPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :creas_strategy_plans, id: :uuid do |t|
      t.references :user,  null: false, type: :uuid, foreign_key: true
      t.references :brand, null: false, type: :uuid, foreign_key: true
      t.string  :strategy_name
      t.string  :month, null: false # YYYY-MM
      t.string  :objective_of_the_month, null: false # awareness|engagement|sales|community
      t.integer :frequency_per_week, null: false
      t.jsonb   :monthly_themes, null: false, default: []
      t.jsonb   :resources_override, null: false, default: {}
      t.jsonb   :content_distribution, null: false, default: {}
      t.jsonb   :weekly_plan, null: false, default: []
      t.jsonb   :remix_duet_plan, null: false, default: {}
      t.jsonb   :publish_windows_local, null: false, default: {}
      t.jsonb   :brand_snapshot, null: false, default: {}
      t.jsonb   :raw_payload, null: false, default: {}
      t.jsonb   :meta, null: false, default: {}
      t.timestamps
    end
    add_index :creas_strategy_plans, [ :brand_id, :month ]
  end
end
