class AddFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    unless table_exists?(:users)
      create_table :users do |t|
        t.string :email, null: false, default: ""
        t.string :encrypted_password, null: false, default: ""
        t.string :reset_password_token
        t.datetime :reset_password_sent_at
        t.datetime :remember_created_at

        t.timestamps null: false
      end

      add_index :users, :email, unique: true
      add_index :users, :reset_password_token, unique: true
    end

    add_column :users, :username, :string unless column_exists?(:users, :username)
    add_column :users, :bio, :text unless column_exists?(:users, :bio)
    add_column :users, :role, :integer unless column_exists?(:users, :role)
  end
end
