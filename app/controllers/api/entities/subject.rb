module API
  module Entities
    class Subject < Grape::Entity
      expose :id
      expose :name
      expose :description
      expose :question_amount
      expose :question_bank_amount do |subject|
        subject.questions.size
      end
      expose :pass_score
      expose :test_duration
      expose :user_id
      expose :created_at
      expose :updated_at
      expose :deleted_at, expose_nil: false
    end
  end
end
