class DetailAnswer < ApplicationRecord
  belongs_to :answer
  belongs_to :test_question
end
