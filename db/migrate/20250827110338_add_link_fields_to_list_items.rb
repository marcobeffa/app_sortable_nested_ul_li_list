class AddLinkFieldsToListItems < ActiveRecord::Migration[8.0]
  def change
    add_column :list_items, :link_item_id, :integer
    add_column :list_items, :link, :boolean, default: false
    add_index :list_items, :link_item_id
  end
end
