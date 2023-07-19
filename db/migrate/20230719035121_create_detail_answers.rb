class CreateDetailAnswers < ActiveRecord::Migration[6.1]
  def change
    create_table :detail_answers do |t|
      t.bigint :test_question_id
      t.bigint :answer_id

      t.timestamps
    end
    add_index :detail_answers, :test_question_id
    add_index :detail_answers, :answer_id
    add_index :detail_answers, [:test_question_id, :answer_id], unique: true
  end
end
