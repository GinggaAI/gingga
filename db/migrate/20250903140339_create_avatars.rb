class CreateAvatars < ActiveRecord::Migration[8.0]
  def change
    create_table :avatars, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :avatar_id, null: false
      t.string :name, null: false
      t.string :provider, null: false
      t.string :status, default: 'active'
      t.text :preview_image_url
      t.string :gender
      t.boolean :is_public, default: false
      t.text :raw_response

      t.timestamps
    end

    add_index :avatars, [ :user_id, :provider ]
    add_index :avatars, [ :avatar_id, :provider, :user_id ], unique: true, name: 'index_avatars_on_unique_avatar_per_user_provider'
    add_index :avatars, :status
    add_index :avatars, :provider
  end
end
