class AddExpandedToListItems < ActiveRecord::Migration[8.0]
  def change
    add_column :list_items, :expanded, :boolean, default: false
  end
end
