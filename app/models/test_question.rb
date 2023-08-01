class TestQuestion < ApplicationRecord
  acts_as_paranoid
  belongs_to :question
  belongs_to :test
  has_many :detail_answers, dependent: :destroy
  scope :order_asc_question_ids, ->{order question_id: :asc}
  scope :by_array_of_ids, ->(array){where "id IN (#{array.join ','})"}
  has_many :answers, through: :detail_answers

  def first_answer_id
    answers.first&.id
  end
end
