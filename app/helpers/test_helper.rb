module TestHelper
  def set_first_time_left_tick
    Time.at(get_time_left_in_second).utc.strftime("%H:%M:%S")
  end

  def get_time_left_in_second
    time = @test.subject.test_duration * 60 - (Time.zone.now - @test.start_time)
    time.round.positive? ? time : 0
  end

  def set_method_fields_for question
    return :first_answer_id if question.single_choice?

    :answer_ids
  end

  def check_disable
    return {disabled: false} if @test.doing?

    {disabled: :set_disabled}
  end

  def set_status test
    return t "tests.index.in_progress" if test.doing?

    return t "tests.index.passed" if test.passed?

    t "tests.index.failed"
  end

  def set_correct_class test_question, answer_form
    return if @test.doing?

    # cau dung
    return "bg-green-light" if answer_form.object.is_correct?

    # cau chon sai
    "bg-red-light" if test_question.answers.include? answer_form.object
  end

  def question_passed? test_question
    return if @test.doing?

    if test_question.question.single_choice?
      test_question.answers.first&.is_correct?
    else
      answered_ids = test_question.answers.pluck(:id)
      correct_ids = test_question.question.answers.select(&:is_correct?)
                                 .pluck(:id)
      answered_ids.size == correct_ids.size &&
        answered_ids.sort == correct_ids.sort
    end
  end

  def completed_tests tests
    tests.completed
  end

  def progressing_tests tests
    tests.progressing
  end
end
