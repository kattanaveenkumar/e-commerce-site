class CreateOptionValues < ActiveRecord::Migration[5.2]
  def change
    create_table :option_values do |t|
      t.integer :option_id
      t.string :value_name

      t.timestamps
    end
  end
end
