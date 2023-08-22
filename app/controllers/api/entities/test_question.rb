module API
  module Entities
    class TestQuestion < Grape::Entity
      expose :id
      expose :question, using: API::Entities::QuestionWithAnswers
      expose :answers, as: :chosen_answers, with: API::Entities::Answer
      expose :correct, if: ->(object, _options){!object.test.doing?}
    end
  end
end
