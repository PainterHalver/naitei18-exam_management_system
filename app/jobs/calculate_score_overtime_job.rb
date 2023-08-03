class CalculateScoreOvertimeJob < ApplicationJob
  queue_as :default

  def perform test_id
    # Do something later
    corrected = []
    test = Test.includes(:subject,
                         test_questions: [:answers, {question: :answers}])
               .find_by(id: test_id)
    return unless test.present? && test&.doing?

    if DetailAnswer.by_test_question_ids(test.test_question_ids).empty?
      test.update({score: 0,
                   end_time: Time.zone.now,
                   status: :failed})
    else
      score = calculate_score test.test_questions, corrected
      update_test test, score, corrected
    end
  rescue ActiveRecord::Rollback
    flash[:danger] = t "tests.do.answer_error"
    redirect_to root_path
  end

  private

  def update_test test, score, corrected
    ActiveRecord::Base.transaction do
      update_test_result test, score
      TestQuestion.by_array_of_ids(corrected).update(correct: true)
    end
  end

  def update_test_result test, score
    rate = score * 1.0 / test.subject.question_amount * 100
    check_pass = rate > test.subject.pass_score ? 1 : 2
    test.update!(status: check_pass, score: score, end_time: Time.zone.now)
  end

  def calculate_score test_questions, corrected
    score = 0
    test_questions.each do |test_question|
      true_answers = test_question.question.answers
                                  .filter(&:is_correct).pluck(:id)
      answers = test_question.answers.pluck(:id)
      next if true_answers.size != answers.size

      if true_answers.sort == answers.sort
        score += 1
        corrected << test_question.id
      end
    end
    score
  end
end
