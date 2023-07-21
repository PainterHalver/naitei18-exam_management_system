class TestQuestion < ApplicationRecord
  belongs_to :question
  belongs_to :test
  has_many :detail_answers, dependent: :destroy
  scope :order_asc_question_ids, ->{order :question_id}
end
