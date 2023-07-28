class CreateSubjects < ActiveRecord::Migration[6.1]
  def change
    create_table :subjects do |t|
      t.string :name, index: {unique: true, name: "index_subjects_on_name"}
      t.string :description
      t.integer :question_amount
      t.float :pass_score
      t.integer :test_duration
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
