class TestQuestion < ApplicationRecord
  belongs_to :question
  belongs_to :test
  has_many :detail_answers, dependent: :destroy
end
