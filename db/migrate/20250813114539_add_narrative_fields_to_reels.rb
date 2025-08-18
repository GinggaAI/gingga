class AddNarrativeFieldsToReels < ActiveRecord::Migration[8.0]
  def change
    add_column :reels, :title, :string
    add_column :reels, :description, :text
    add_column :reels, :category, :string
    add_column :reels, :format, :string
    add_column :reels, :story_content, :text
    add_column :reels, :music_preference, :string
    add_column :reels, :style_preference, :string
    add_column :reels, :use_ai_avatar, :boolean
    add_column :reels, :additional_instructions, :text
  end
end
