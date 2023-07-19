class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email, index: { unique: true, name: "index_users_on_email" }
      t.string :password_digest
      t.string :remember_digest
      t.string :activation_digest
      t.string :reset_digest
      t.datetime :activated_at
      t.boolean :activated, default: false
      t.datetime :reset_send_at
      t.boolean :is_supervisor

      t.timestamps
    end
  end
end
