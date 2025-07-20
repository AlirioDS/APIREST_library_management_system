class CreateBorrowings < ActiveRecord::Migration[8.0]
  def change
    create_table :borrowings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.datetime :borrowed_at, null: false
      t.datetime :due_at, null: false
      t.datetime :returned_at
      t.string :status, default: 'borrowed', null: false

      t.timestamps
    end

    add_index :borrowings, [ :user_id, :book_id ]
    add_index :borrowings, :status
    add_index :borrowings, :due_at
    add_index :borrowings, :borrowed_at

    # Ensure user can't borrow the same book multiple times while not returned
    add_index :borrowings, [ :user_id, :book_id, :returned_at ],
              unique: true,
              where: "returned_at IS NULL",
              name: "index_borrowings_on_user_book_active"
  end
end
