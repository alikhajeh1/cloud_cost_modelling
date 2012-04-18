class AddCurrencyToUser < ActiveRecord::Migration
  def change
    add_column :users, :currency, :string
    User.all.each { |u| u.update_attributes!(:currency => 'USD') }
  end
end
