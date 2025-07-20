class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :role, default: 'member', null: false
      t.string :first_name
      t.string :last_name
      t.datetime :last_signed_in_at
      
      t.timestamps
    end
    
    add_index :users, :email_address, unique: true
    add_index :users, :role
  end
end 
