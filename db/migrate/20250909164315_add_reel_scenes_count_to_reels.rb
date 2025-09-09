class AddReelScenesCountToReels < ActiveRecord::Migration[8.0]
  def change
    add_column :reels, :reel_scenes_count, :integer, default: 0, null: false
    
    # Reset counter cache for existing records
    reversible do |dir|
      dir.up do
        Reel.find_each do |reel|
          Reel.reset_counters(reel.id, :reel_scenes)
        end
      end
    end
  end
end
