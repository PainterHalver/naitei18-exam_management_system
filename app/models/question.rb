class Question < ApplicationRecord
  belongs_to :subject
  belongs_to :creator, class_name: User.name, foreign_key: :user_id
  has_many :answers, dependent: :destroy
  has_many :test_questions, dependent: :destroy
end
