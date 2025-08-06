class AddVideoFieldsToReels < ActiveRecord::Migration[8.0]
  def change
    add_column :reels, :heygen_video_id, :string
    add_column :reels, :video_url, :string
    add_column :reels, :thumbnail_url, :string
    add_column :reels, :duration, :integer
  end
end
