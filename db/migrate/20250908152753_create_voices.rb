class CreateVoices < ActiveRecord::Migration[8.0]
  def change
    create_table :voices, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :voice_id
      t.string :language
      t.string :gender
      t.string :name
      t.string :preview_audio
      t.boolean :support_pause
      t.boolean :emotion_support
      t.boolean :support_interactive_avatar
      t.boolean :support_locale
      t.boolean :active

      t.timestamps
    end
    add_index :voices, :voice_id
    add_index :voices, [ :user_id, :voice_id ], unique: true
  end
end
