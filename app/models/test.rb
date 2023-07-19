class Test < ApplicationRecord
  belongs_to :subject
  belongs_to :user
  has_many :test_questions
end
