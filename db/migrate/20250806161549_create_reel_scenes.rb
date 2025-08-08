class CreateReelScenes < ActiveRecord::Migration[8.0]
  def change
    create_table :reel_scenes, id: :uuid do |t|
      t.references :reel, null: false, foreign_key: true, type: :uuid
      t.string :avatar_id
      t.string :voice_id
      t.text :script
      t.integer :scene_number

      t.timestamps
    end
  end
end
