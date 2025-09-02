class RemoveWeekIndexFromCreasContentItems < ActiveRecord::Migration[8.0]
  def change
    remove_column :creas_content_items, :week_index, :integer
  end
end
