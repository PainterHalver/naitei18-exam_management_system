module API
  module Entities
    class TestQuestion < Grape::Entity
      expose :question, using: API::Entities::Question
      expose :answers
    end
  end
end
