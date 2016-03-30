class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.belongs_to :user
      t.string :user_name
      t.string :item
      t.float :price, scale: 2
      t.timestamps
    end
  end
end
