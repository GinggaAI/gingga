class CreateCreasPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :creas_posts, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :creas_strategy_plan, null: false, type: :uuid, foreign_key: true
      t.string  :origin_id # id or origin_id provided by model
      t.string  :content_name, null: false
      t.string  :status, null: false
      t.date    :creation_date, null: false
      t.date    :publish_date, null: false
      t.string  :publish_datetime_local
      t.string  :timezone
      t.string  :content_type, null: false, default: "Video"
      t.string  :platform, null: false, default: "Instagram Reels"
      t.string  :aspect_ratio, null: false, default: "9:16"
      t.string  :language
      t.jsonb   :subtitles, null: false, default: {}
      t.jsonb   :dubbing, null: false, default: {}
      t.string  :pilar, null: false
      t.string  :template, null: false
      t.string  :video_source, null: false
      t.text    :post_description, null: false
      t.text    :text_base, null: false
      t.text    :hashtags, null: false
      t.jsonb   :shotplan, null: false, default: {}
      t.jsonb   :assets, null: false, default: {}
      t.jsonb   :accessibility, null: false, default: {}
      t.string  :kpi_focus
      t.string  :success_criteria
      t.string  :compliance_check
      t.jsonb   :raw_payload, null: false, default: {}
      t.jsonb   :meta, null: false, default: {}
      t.timestamps
    end
    add_index :creas_posts, [ :user_id, :origin_id ], unique: true
    add_index :creas_posts, :shotplan, using: :gin
    add_index :creas_posts, :assets,   using: :gin
  end
end
