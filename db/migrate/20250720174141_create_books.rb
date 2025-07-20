class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :author, null: false
      t.string :isbn
      t.text :description
      t.string :genre
      t.integer :publication_year
      t.string :publisher
      t.integer :total_copies, default: 1, null: false
      t.integer :available_copies, default: 1, null: false
      t.string :status, default: 'available', null: false
      
      t.timestamps
    end
    
    add_index :books, :title
    add_index :books, :author
    add_index :books, :isbn, unique: true
    add_index :books, :genre
    add_index :books, :status
  end
end 
