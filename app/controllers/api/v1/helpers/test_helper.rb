module API::V1::Helpers::TestHelper
  extend ActiveSupport::Concern
  extend Grape::API::Helpers

  included do
    helpers do
      def add_questions_to_test test, subject
        amount = subject.question_amount
        test.questions << subject.questions.sample(amount).sort
      end

      def inform_error_for_test_create subject
        error!("Subject not exists", :forbidden) unless subject
        return unless subject.questions.count < subject.question_amount

        error!("Not enough questions", :forbidden)
      end
    end

    helpers do
      def enqueue_job
        time = (@test.subject.test_duration + 0.1).minutes
        CalculateScoreOvertimeJob.set(wait: time)
                                 .perform_later(@test.id)
      end

      def submit_test corrected
        ActiveRecord::Base.transaction do
          update_test(calculate_score(@answers, corrected))
          unless corrected.empty?
            result = TestQuestion.by_array_of_ids(corrected)
                                 .update_all(correct: true)
            raise ActiveRecord::Rollback if result != corrected.size
          end
        end
      rescue ActiveRecord::Rollback
        error!(test.errors.full_messages, 500)
      end

      def update_saved_test
        @test.update!(pause_time: Time.zone.now)
      end
    end

    helpers do
      def save_answers detail_answers
        ActiveRecord::Base.transaction do
          DetailAnswer.by_test_question_ids(@test_questions_ids).delete_all
          unless DetailAnswer.by_test_question_ids(@test_questions_ids).empty?
            raise ActiveRecord::Rollback
          end

          @answers.each_with_index do |answer, index|
            next if check_invalid_answer answer

            add_answer_to_question(answer, detail_answers, index)
          end
          if detail_answers.empty?
            update_saved_test
          else
            create_detail_answers detail_answers
          end
        end
      rescue ActiveRecord::Rollback
        error!(test.errors.full_messages, 500)
      end

      def create_detail_answers detail_answers
        create_relations detail_answers
        return if Settings.update_commit.include? params[:commit]

        ActiveRecord::Base.transaction do
          update_saved_test
        end
      rescue ActiveRecord::Rollback
        error!(test.errors.full_messages, 500)
      end

      def update_test score
        rate = score * 1.0 / @test.subject.question_amount * 100
        check_pass = rate > @test.subject.pass_score ? 1 : 2
        @test.update!(status: check_pass, score: score, end_time: Time.zone.now)
      end
    end

    helpers do
      def post_data_handle
        @test_questions_ids = params.dig(:test, :test_question)&.keys
        data = params.dig(:test, :test_question)&.values
        @answers = data.map{|i| i[:first_answer_id] || i[:answer_ids]} if data

        return if @answers && @test_questions_ids

        error!("data not valid", 422)
      end

      def true_answers
        @true_answers = @test.questions.includes(:answers)
                             .where(answers: {is_correct: true})
                             .map{|i| i.answers.map(&:id)}
      end

      def check_invalid_answer answer
        answer == "" || (answer.is_a?(Array) && answer.size == 1)
      end

      def require_doing_test
        return if @test.doing?

        error!("test has finished", :forbidden)
      end
    end
  end
end
