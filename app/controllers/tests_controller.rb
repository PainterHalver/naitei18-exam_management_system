class TestsController < ApplicationController
  before_action :require_login
  before_action :load_test, only: [:update, :show, :edit]
  before_action :has_authorization_with_test?, only: [:show]
  before_action :post_data_handle, only: [:update]

  def create
    @test = current_user.tests.build(test_params)
    if @test.save
      add_questions_to_test
      redirect_to edit_test_path @test
    else
      flash.now[:danger] = t "tests.errors.questions_fail"
      @subject = @subject = @test.subject
      render "subjects/show"
    end
  end

  def index
    redirect_back fallback_location: request.referer
  end

  def show; end

  def update
    detail_answers = []
    answer_ids = @update_params.map{|i| i[:id]}
    @update_params.each_with_index do |update_param, index|
      next if check_invalid_answer(update_param[:id])

      add_answer_to_question(@test_questions_ids, update_param[:id],
                             detail_answers, index)
    end
    ActiveRecord::Base.transaction do
      create_relations(detail_answers)
      update_test(calculate_score(answer_ids))
    end
  rescue ActiveRecord::Rollback
    flash[:danger] = t "tests.do.answer_error"
    redirect_back
  end

  def edit; end

  private

  def post_data_handle
    @test_questions_ids = @test.test_questions
                               .order_asc_question_ids.pluck(:id)
    @update_params = params.dig(:test, :question)&.values
    return if @update_params

    flash[:danger] = "tests.do.post_error"
    redirect_to request.referer
  end

  def check_invalid_answer answer
    return true if answer == "" ||
                   (answer.is_a?(Array) && answer.size == 1)

    false
  end

  def update_test score
    rate = score * 1.0 / @test.subject.question_amount * 100
    check_pass = rate > @test.subject.pass_score ? 1 : 2
    @test.update!(status: check_pass, score: score)
  end

  def calculate_score answer_ids
    score = 0
    true_answers = @test.questions.includes(:answers)
                        .where(answers: {is_correct: true})
                        .map{|i| i.answers.map(&:id)}
    answer_ids.each_with_index do |answer, index|
      next if answer == "" || (answer.is_a?(Array) &&
              (answer.size == 1 || answer.size - 1 != true_answers[index].size))

      score += check_true_false(answer, true_answers[index])
    end
    score
  end

  def check_true_false answer, true_answer
    if answer.is_a?(String)
      return 1 if true_answer.include? answer.to_i
    else
      check = true
      answer[1..].each do |i|
        unless true_answer.include? i.to_i
          check = false
          break
        end
      end
      return 1 if check
    end
    0
  end

  def create_relations detail_answers
    if DetailAnswer.insert_all! detail_answers
      flash[:success] = t "tests.do.success"
      redirect_to subjects_path
    else
      flash[:error] = t "test.do.fail"
      redirect_back
    end
  end

  def build_data_answer_for_test test_question_id, answer_id
    {test_question_id: test_question_id,
     answer_id: answer_id,
     created_at: Time.zone.now,
     updated_at: Time.zone.now}
  end

  def add_multiple_answers answer_ids, test_questions_ids, detail_answers, index
    answer_ids.each do |i|
      detail_answers << build_data_answer_for_test(test_questions_ids[index], i)
    end
  end

  def add_answer_to_question test_questions_ids, answers, detail_answers, index
    if answers.is_a?(Array)
      add_multiple_answers(answers[1..], test_questions_ids,
                           detail_answers, index)
    else
      detail_answers << build_data_answer_for_test(test_questions_ids[index],
                                                   answers)
    end
  end

  def load_test
    @test = Test.find_by id: params[:id]
    return if @test

    flash[:danger] = t "tests.errors.not_found"
    redirect_back
  end

  def add_questions_to_test
    subject = @test.subject
    amount = subject.question_amount
    @test.questions << subject.questions.sample(amount).sort
  end

  def test_params
    params.permit :subject_id, :remaining_time, :start_time
  end

  def has_authorization_with_test?
    return if current_user.is_supervisor? ||
              current_user.id = @test.user_id

    flash[:danger] = t "tests.show.not_authorized"
    redirect_back
  end
end
