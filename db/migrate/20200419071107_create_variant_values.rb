class CreateVariantValues < ActiveRecord::Migration[5.2]
  def change
    create_table :variant_values do |t|
      t.integer :product_variant_id
      t.integer :product_option_id
      t.integer :option_value_id

      t.timestamps
    end
  end
end
