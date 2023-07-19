class CreateTestQuestions < ActiveRecord::Migration[6.1]
  def change
    create_table :test_questions do |t|
      t.bigint :test_id
      t.bigint :question_id

      t.timestamps
    end
    add_index :test_questions, :test_id
    add_index :test_questions, :question_id
    add_index :test_questions, [:test_id, :question_id], unique: true
  end
end
