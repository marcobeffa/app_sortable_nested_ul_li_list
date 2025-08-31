class AddStylingFieldsToListItems < ActiveRecord::Migration[8.0]
  def change
    add_column :list_items, :slug, :string
    add_column :list_items, :text_color, :string, default: '#374151'
    add_column :list_items, :background_color, :string, default: '#ffffff'
    add_index :list_items, :slug, unique: true
  end
end
