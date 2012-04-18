class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.integer :user_id
      t.string :name
      t.text :description
      t.references :reportable, :polymorphic => true
      t.datetime :start_date
      t.datetime :end_date
      t.datetime :completed_at
      t.string :status
      t.text :xml
      t.string :xslt_file
      t.text :html

		  t.timestamps
    end

    change_table :reports do |t|
      t.index :user_id
      t.index [:reportable_id, :reportable_type]
    end
  end
end
