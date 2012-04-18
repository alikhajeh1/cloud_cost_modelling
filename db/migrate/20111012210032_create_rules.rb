class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.integer  :user_id
      t.integer  :pattern_id
      t.string   :rule_type
      t.string   :year
      t.string   :month
      t.string   :day
      t.string   :hour
      t.string   :variation
      t.decimal  :value, :precision => 30, :scale => 10

      t.timestamps
    end

    change_table :rules do |t|
      t.index :user_id
      t.index :pattern_id
    end

  end
end
