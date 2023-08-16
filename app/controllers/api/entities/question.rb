module API
  module Entities
    class Question < Grape::Entity
      unexpose :user_id
      expose :content, :question_type, :created_at,
             :updated_at, :subject_id, :id
      expose :answers_count do |question|
        question.answers.size
      end
    end

    class QuestionWithAnswers < Question
      expose :answers, using: API::Entities::Answer
    end
  end
end
