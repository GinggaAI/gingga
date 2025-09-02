class RenameReelModeToTemplate < ActiveRecord::Migration[8.0]
  def change
    rename_column :reels, :mode, :template
  end
end
