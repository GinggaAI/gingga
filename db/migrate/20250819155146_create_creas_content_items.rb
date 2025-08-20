class CreateCreasContentItems < ActiveRecord::Migration[8.0]
  def change
    create_table :creas_content_items, id: :uuid do |t|
      # References
      t.references :creas_strategy_plan, null: false, type: :uuid, foreign_key: true
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :brand, null: false, type: :uuid, foreign_key: true

      # Identifiers
      t.string :content_id, null: false
      t.string :origin_id
      t.string :origin_source

      # Scheduling
      t.integer :week
      t.integer :week_index
      t.string :scheduled_day
      t.date :publish_date
      t.datetime :publish_datetime_local
      t.string :timezone

      # Content
      t.string :content_name
      t.string :status
      t.date :creation_date
      t.string :content_type
      t.string :platform
      t.string :aspect_ratio
      t.string :language
      t.string :pilar

      # Technical
      t.string :template
      t.string :video_source
      t.text :post_description
      t.text :text_base
      t.text :hashtags

      # JSONB fields
      t.jsonb :subtitles, null: false, default: {}
      t.jsonb :dubbing, null: false, default: {}
      t.jsonb :shotplan, null: false, default: {}
      t.jsonb :assets, null: false, default: {}
      t.jsonb :accessibility, null: false, default: {}
      t.jsonb :meta, null: false, default: {}

      t.timestamps
    end

    # Indexes (references automatically create indexes for foreign keys)
    add_index :creas_content_items, [ :creas_strategy_plan_id, :origin_id ],
              name: 'index_creas_content_items_on_strategy_plan_and_origin_id'
    add_index :creas_content_items, :content_id, unique: true
    add_index :creas_content_items, :status, where: "status IS NOT NULL"
  end
end
