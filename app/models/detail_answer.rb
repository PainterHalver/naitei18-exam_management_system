class DetailAnswer < ApplicationRecord
  belongs_to :answer
  belongs_to :test_question

  scope :by_test_question_ids,
        ->(array){where "test_question_id IN (#{array.join ','})"}
end
