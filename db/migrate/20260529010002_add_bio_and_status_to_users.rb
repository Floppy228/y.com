class AddBioAndStatusToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :bio, :text
    add_column :users, :status, :string
  end
end
