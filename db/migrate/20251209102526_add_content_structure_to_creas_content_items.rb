class AddContentStructureToCreasContentItems < ActiveRecord::Migration[8.0]
  def change
    add_column :creas_content_items, :content_structure, :string
    add_index :creas_content_items, :content_structure

    # Add comment for documentation
    change_column_comment :creas_content_items, :content_structure,
      "Narrative structure from Content Structures registry (e.g., 'voxa_radiant_rankings')"
  end
end
