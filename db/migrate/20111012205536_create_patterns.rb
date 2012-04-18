class CreatePatterns < ActiveRecord::Migration
  def change
    create_table :patterns do |t|
      t.integer  :user_id
      t.string   :name
      t.text     :description

      t.timestamps
    end

    change_table :patterns do |t|
      t.index :user_id
    end

  end
end
