class CreateApiTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :api_tokens, id: :uuid do |t|
      t.string :provider
      t.string :mode
      t.text :encrypted_token
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.boolean :valid

      t.timestamps
    end
  end
end
