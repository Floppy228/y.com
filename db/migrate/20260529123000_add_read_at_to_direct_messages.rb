class AddReadAtToDirectMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :direct_messages, :read_at, :datetime
  end
end
