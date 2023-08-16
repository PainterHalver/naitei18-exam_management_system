module API
  module Entities
    class Question < Grape::Entity
      unexpose :user_id
      expose :content, :question_type, :created_at,
             :updated_at, :subject_id, :id
    end
  end
end
