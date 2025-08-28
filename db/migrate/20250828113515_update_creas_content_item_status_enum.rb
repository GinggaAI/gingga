class UpdateCreasContentItemStatusEnum < ActiveRecord::Migration[8.0]
  def up
    # Add the new status to allow in_progress
    # Note: We're not using database-level enums, just validating in the model
    # So this migration documents the change but doesn't modify the schema
  end

  def down
    # No changes needed since we're using model-level validation
  end
end
