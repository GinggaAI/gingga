class AddBatchingFieldsToCreasContentItem < ActiveRecord::Migration[8.0]
  def change
    add_column :creas_content_items, :batch_number, :integer
    add_column :creas_content_items, :batch_total, :integer
  end
end
