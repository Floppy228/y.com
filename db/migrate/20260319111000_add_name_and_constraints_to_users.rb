class AddNameAndConstraintsToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :name, :string unless column_exists?(:users, :name)
    add_index :users, :username, unique: true unless index_exists?(:users, :username)

    if column_exists?(:users, :role)
      change_column_default :users, :role, from: nil, to: 0
      execute "UPDATE users SET role = 0 WHERE role IS NULL"
      change_column_null :users, :role, false
    end
  end

  def down
    if column_exists?(:users, :role)
      change_column_null :users, :role, true
      change_column_default :users, :role, from: 0, to: nil
    end

    remove_index :users, :username if index_exists?(:users, :username)
    remove_column :users, :name if column_exists?(:users, :name)
  end
end
