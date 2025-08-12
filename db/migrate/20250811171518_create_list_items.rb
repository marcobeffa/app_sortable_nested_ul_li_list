# Sostituisci il contenuto della migrazione CreateListItems con questo:
class CreateListItems < ActiveRecord::Migration[8.0]
  def change
    create_table :list_items do |t|
      t.string :title, null: false
      t.text :content
      t.integer :position, default: 0
      t.string :ancestry, null: true
      t.timestamps
    end

    add_index :list_items, :ancestry
    add_index :list_items, :position
  end
end
