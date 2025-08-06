class CreateReels < ActiveRecord::Migration[8.0]
  def change
    create_table :reels, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :mode
      t.string :video_id
      t.string :status
      t.text :preview_url

      t.timestamps
    end
  end
end
