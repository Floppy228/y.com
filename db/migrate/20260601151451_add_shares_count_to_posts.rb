class AddSharesCountToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :shares_count, :integer, default: 0, null: false
  end
end
