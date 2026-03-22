class MakeUserEmailAndUsernameCaseInsensitiveUnique < ActiveRecord::Migration[8.1]
  def up
    if index_exists?(:users, :email, name: "index_users_on_email")
      remove_index :users, name: "index_users_on_email"
    end

    if index_exists?(:users, :username, name: "index_users_on_username")
      remove_index :users, name: "index_users_on_username"
    end

    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email" unless index_exists?(:users, "LOWER(email)", name: "index_users_on_lower_email")
    add_index :users, "LOWER(username)", unique: true, name: "index_users_on_lower_username" unless index_exists?(:users, "LOWER(username)", name: "index_users_on_lower_username")
  end

  def down
    remove_index :users, name: "index_users_on_lower_email" if index_exists?(:users, "LOWER(email)", name: "index_users_on_lower_email")
    remove_index :users, name: "index_users_on_lower_username" if index_exists?(:users, "LOWER(username)", name: "index_users_on_lower_username")

    add_index :users, :email, unique: true, name: "index_users_on_email" unless index_exists?(:users, :email, name: "index_users_on_email")
    add_index :users, :username, unique: true, name: "index_users_on_username" unless index_exists?(:users, :username, name: "index_users_on_username")
  end
end
