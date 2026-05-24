class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.text :content, null: false     # текст поста
      t.references :user, null: false, foreign_key: true  # кто написал

      t.timestamps  # created_at и updated_at
    end
  end
end