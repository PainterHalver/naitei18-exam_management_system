class Answer < ApplicationRecord
  belongs_to :question
  has_many :detail_answers, dependent: :destroy
end
