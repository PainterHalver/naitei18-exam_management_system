class AddDeletedAtToTestQuestions < ActiveRecord::Migration[6.1]
  def change
    add_column :test_questions, :deleted_at, :datetime
    add_index :test_questions, :deleted_at
  end
end
