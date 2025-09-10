class AddVideoTypeToReelScenes < ActiveRecord::Migration[8.0]
  def change
    add_column :reel_scenes, :video_type, :string, default: 'avatar'
  end
end
