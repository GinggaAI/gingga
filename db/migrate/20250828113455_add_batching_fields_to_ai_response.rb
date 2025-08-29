class AddBatchingFieldsToAiResponse < ActiveRecord::Migration[8.0]
  def change
    add_column :ai_responses, :batch_number, :integer
    add_column :ai_responses, :total_batches, :integer
    add_column :ai_responses, :batch_id, :string
  end
end
