class CreateProductVariants < ActiveRecord::Migration[5.2]
  def change
    create_table :product_variants do |t|
      t.integer :product_id
      t.integer :sku_id

      t.timestamps
    end
  end
end
