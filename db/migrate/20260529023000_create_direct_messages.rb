class CreateDirectMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :direct_messages do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.text :content, null: false

      t.timestamps
    end

    add_index :direct_messages, [:sender_id, :recipient_id, :created_at]
    add_index :direct_messages, [:recipient_id, :sender_id, :created_at]
  end
end
