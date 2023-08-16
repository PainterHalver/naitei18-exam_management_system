module API
  module Entities
    class Answer < Grape::Entity
      unexpose :user_id
      expose :content, :is_correct
    end
  end
end
