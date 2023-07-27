class DeleteActivationDigestFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :activation_digest, :string
  end
end
