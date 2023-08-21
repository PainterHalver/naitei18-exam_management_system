module API
  module Entities
    class Answer < Grape::Entity
      unexpose :user_id
      expose :id, :content, :is_correct
    end
  end
end
