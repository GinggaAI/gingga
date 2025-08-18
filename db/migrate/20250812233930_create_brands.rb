class CreateBrands < ActiveRecord::Migration[8.0]
  def change
    create_table :brands, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :industry, null: false
      t.text   :value_proposition
      t.text   :mission
      t.string :voice, null: false
      t.string :content_language
      t.string :account_language
      t.jsonb  :subtitle_languages, null: false, default: []
      t.jsonb  :dub_languages, null: false, default: []
      t.string :region
      t.string :timezone
      t.jsonb  :guardrails, null: false, default: { banned_words: [], claims_rules: "", tone_no_go: [] }
      t.jsonb  :resources,  null: false, default: { podcast_clips: false, editing: false, ai_avatars: false, kling: false, stock: false, budget: false }
      t.timestamps
    end
    add_index :brands, [ :user_id, :slug ], unique: true
  end
end
