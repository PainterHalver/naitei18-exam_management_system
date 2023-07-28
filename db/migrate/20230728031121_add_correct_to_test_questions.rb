class AddCorrectToTestQuestions < ActiveRecord::Migration[6.1]
  def change
    add_column :test_questions, :correct, :boolean, default: false
  end
end
