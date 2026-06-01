class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :notifiable_type, null: false
      t.integer :notifiable_id, null: false
      t.string :action, null: false
      t.datetime :read_at
      t.timestamps
    end

    add_index :notifications, [:user_id, :read_at]
    add_index :notifications, [:notifiable_type, :notifiable_id]
  end
end
