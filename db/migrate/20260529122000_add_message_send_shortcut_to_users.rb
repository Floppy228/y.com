class AddMessageSendShortcutToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :message_send_shortcut, :string, null: false, default: "enter"
  end
end
