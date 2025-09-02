class CreateAiResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_responses, id: :uuid do |t|
      t.string :service_name
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :ai_model
      t.string :prompt_version
      t.jsonb :raw_request
      t.jsonb :raw_response
      t.jsonb :metadata

      t.timestamps
    end

    add_index :ai_responses, :service_name
    add_index :ai_responses, :ai_model
    add_index :ai_responses, :prompt_version
    add_index :ai_responses, :created_at
    add_index :ai_responses, [ :service_name, :created_at ]
  end
end
