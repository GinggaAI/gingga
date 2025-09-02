class AddDayOfWeekToCreasContentItems < ActiveRecord::Migration[8.0]
  def change
    add_column :creas_content_items, :day_of_the_week, :string

    # Add index for efficient querying by day of week
    add_index :creas_content_items, :day_of_the_week

    # Add comment for clarity
    change_column_comment :creas_content_items, :day_of_the_week,
      "Suggested day of the week for publishing (Monday, Tuesday, etc.)"
  end
end
