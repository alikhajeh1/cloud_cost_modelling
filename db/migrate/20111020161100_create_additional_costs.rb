class CreateAdditionalCosts < ActiveRecord::Migration
  def change
    create_table :additional_costs do |t|
      t.integer :user_id
      t.string  :name
      t.text    :description
      t.decimal :cost_baseline, :precision => 30, :scale => 10

      t.timestamps
    end

    change_table :additional_costs do |t|
      t.index :user_id
    end
  end
end
