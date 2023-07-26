class Answer < ApplicationRecord
  acts_as_paranoid
  belongs_to :question
  has_many :detail_answers, dependent: :destroy
  has_many :test_questions, through: :detail_answers

  validates :content, presence: true

  def set_disabled
    true
  end
end
