module API
  module Entities
    class Test < Grape::Entity
      expose :start_time, :end_time, :score, :status, :created_at, :subject_id
      expose :test_questions,
             as: :user_answers, using: API::Entities::TestQuestion
    end
  end
end
