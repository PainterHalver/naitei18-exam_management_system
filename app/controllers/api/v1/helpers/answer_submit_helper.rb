module API::V1::Helpers::AnswerSubmitHelper
  extend ActiveSupport::Concern
  extend Grape::API::Helpers

  included do
    helpers do
      def calculate_score answer_ids, corrected
        score = 0
        answer_ids.each_with_index do |answer, index|
          next if answer == "" || (answer.is_a?(Array) &&
                 (answer.size == 1 ||
                  answer.size - 1 != @true_answers[index].size))

          if is_correct_answer?(answer, @true_answers[index])
            score += 1
            corrected << @test_questions_ids[index]
          end
        end
        score
      end

      def is_correct_answer? answer, true_answer
        return true_answer.include?(answer.to_i) if answer.is_a?(String)
        return false unless answer.is_a?(Array)

        answer[1..].all?{|i| true_answer.include?(i.to_i)}
      end
    end

    helpers do
      def create_relations detail_answers
        DetailAnswer.insert_all! detail_answers
      end

      def build_data_answers test_question_id, answer_id
        {test_question_id: test_question_id,
         answer_id: answer_id,
         created_at: Time.zone.now,
         updated_at: Time.zone.now}
      end

      def add_multiple_answers answer_ids, detail_answers, index
        answer_ids.each do |i|
          detail_answers << build_data_answers(@test_questions_ids[index], i)
        end
      end

      def add_answer_to_question answer, detail_answers, index
        if answer.is_a?(Array)
          return add_multiple_answers(answer[1..],
                                      detail_answers, index)
        end

        detail_answers << build_data_answers(@test_questions_ids[index],
                                             answer)
      end
    end
  end
end
