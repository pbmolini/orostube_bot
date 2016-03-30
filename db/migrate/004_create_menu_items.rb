class CreateMenuItems < ActiveRecord::Migration

  def change
    create_table :menu_items do |t|
      t.date :retrieved_at
      t.string :category
      t.string :name
      t.string :ingredients
      t.float :price
    end
  end

end
