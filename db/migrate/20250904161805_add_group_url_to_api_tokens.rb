class AddGroupUrlToApiTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :api_tokens, :group_url, :text
  end
end
