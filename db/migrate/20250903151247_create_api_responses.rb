class CreateApiResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :api_responses, id: :uuid do |t|
      t.string :provider, null: false
      t.string :endpoint, null: false  
      t.text :request_data
      t.text :response_data
      t.integer :status_code
      t.integer :response_time_ms
      t.boolean :success, default: false
      t.string :error_message
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    
    add_index :api_responses, [:provider, :endpoint]
    add_index :api_responses, [:user_id, :provider]
    add_index :api_responses, [:created_at]
    add_index :api_responses, [:success]
  end
end
