module API
  module Entities
    class Test < Grape::Entity
      expose :start_time, :end_time, :score, :status,
             :created_at, :subject_id, :id
      expose :test_questions, as: :test_content,
             using: API::Entities::TestQuestion
    end
  end
end
