class CreateAudiences < ActiveRecord::Migration[8.0]
  def change
    create_table :audiences, id: :uuid do |t|
      t.references :brand, null: false, type: :uuid, foreign_key: true
      t.string :name
      t.jsonb :demographic_profile, null: false, default: {}
      t.jsonb :interests, null: false, default: []
      t.jsonb :digital_behavior, null: false, default: []
      t.timestamps
    end
  end
end
