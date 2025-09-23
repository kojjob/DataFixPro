class AddStatusColumnToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :status, :string, default: 'active', null: false
    add_index :users, :status
  end
end
