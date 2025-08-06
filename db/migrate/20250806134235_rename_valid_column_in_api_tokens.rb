class RenameValidColumnInApiTokens < ActiveRecord::Migration[8.0]
  def change
    rename_column :api_tokens, :valid, :is_valid
  end
end
