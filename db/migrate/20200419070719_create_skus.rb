class CreateSkus < ActiveRecord::Migration[5.2]
  def change
    create_table :skus do |t|
      t.integer :product_id
      t.string :sku
      t.integer :dealer_id

      t.timestamps
    end
  end
end
