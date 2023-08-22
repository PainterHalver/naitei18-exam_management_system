class TestsController < ApplicationController
  before_action :require_login
  before_action :load_test, :post_data_handle, :true_answers, only: :update
  before_action :load_test_show, only: %i(edit show)
  before_action :require_authorization_with_test_show, only: :show
  before_action :require_authorization_with_test_modification,
                :require_doing_test, only: %i(edit update)
  before_action :require_finished_test, only: :show
  before_action :post_data_handle, only: :update
  before_action :test_available?, only: :create

  def create
    @test = current_user.tests.build(test_params)
    @test.start_time = Time.zone.now
    if @test.save
      add_questions_to_test
      enqueue_job
      redirect_to edit_test_path @test
    else
      flash.now[:danger] = t "tests.errors.questions_fail"
      @subject = @test.subject
      render "subjects/show"
    end
  end

  def index
    redirect_back fallback_location: root_path
  end

  def show
    @test_questions = @test.test_questions
  end

  def update
    corrected = []
    detail_answers = []
    save_answers detail_answers
    if Settings.update_commit.include?(params[:commit])
      if detail_answers.empty?
        @test.update({score: 0,
                      end_time: Time.zone.now,
                      status: 2})
      else
        submit_test corrected
      end
    end
    redirect_to root_path
  rescue ActiveRecord::Rollback
    flash[:danger] = t "tests.do.answer_error"
    redirect_to request.referer
  end

  def edit
    @test_questions = @test.test_questions
  end

  private

  def enqueue_job
    time = (@test.subject.test_duration + 0.1).minutes
    CalculateScoreOvertimeJob.set(wait: time)
                             .perform_later(@test.id)
  end

  def submit_test corrected
    ActiveRecord::Base.transaction do
      update_test(calculate_score(@answers, corrected))
      unless corrected.empty?
        TestQuestion.by_array_of_ids(corrected).update(correct: true)
      end
    end
  end

  def update_saved_test
    @test.update(pause_time: Time.zone.now)
  end

  def save_answers detail_answers
    DetailAnswer.by_test_question_ids(@test_questions_ids).delete_all
    @answers.each_with_index do |answer, index|
      next if check_invalid_answer answer

      add_answer_to_question(@test_questions_ids, answer, detail_answers, index)
    end
    if detail_answers.empty?
      update_saved_test
    else
      create_detail_answers detail_answers
    end
  end

  def create_detail_answers detail_answers
    ActiveRecord::Base.transaction do
      create_relations detail_answers
      update_saved_test unless Settings.update_commit.include? params[:commit]
    end
  end

  def post_data_handle
    @test_questions_ids = params.dig(:test, :test_question)&.keys
    answers_param = params.dig(:test, :test_question)&.values
    if answers_param
      @answers = answers_param.map{|i| i[:first_answer_id] || i[:answer_ids]}
    end
    return if @answers && @test_questions_ids

    flash[:danger] = t "tests.do.post_error"
    redirect_to request.referer
  end

  def true_answers
    @true_answers = @test.questions.includes(:answers)
                         .where(answers: {is_correct: true})
                         .map{|i| i.answers.map(&:id)}
  end

  def check_invalid_answer answer
    return true if answer == "" ||
                   (answer.is_a?(Array) && answer.size == 1)

    false
  end

  def update_test score
    rate = score * 1.0 / @test.subject.question_amount * 100
    check_pass = rate > @test.subject.pass_score ? 1 : 2
    @test.update!(status: check_pass, score: score, end_time: Time.zone.now)
  end

  def calculate_score answer_ids, corrected
    score = 0

    answer_ids.each_with_index do |answer, index|
      next if answer == "" || (answer.is_a?(Array) &&
             (answer.size == 1 || answer.size - 1 != @true_answers[index].size))

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

  def create_relations detail_answers
    DetailAnswer.insert_all! detail_answers
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

  def add_answer_to_question test_questions_ids, answer, detail_answers, index
    if answer.is_a?(Array)
      add_multiple_answers(answer[1..], test_questions_ids,
                           detail_answers, index)
    else
      detail_answers << build_data_answer_for_test(test_questions_ids[index],
                                                   answer)
    end
  end

  def load_test
    @test = Test.find_by id: params[:id]
    return if @test

    flash[:danger] = t "tests.errors.not_found"
    redirect_back fallback_location: root_path
  end

  def load_test_show
    @test = Test.includes(test_questions: [:answers, {question: :answers}])
                .find_by id: params[:id]
    return if @test

    flash[:danger] = t "tests.errors.not_found"
    redirect_back fallback_location: root_path
  end

  def add_questions_to_test
    subject = @test.subject
    amount = subject.question_amount
    @test.questions << subject.questions.sample(amount).sort
  end

  def test_params
    params.permit :subject_id
  end

  def require_authorization_with_test_show
    return if current_user.is_supervisor? ||
              current_user.id == @test.user_id

    flash[:danger] = t "tests.show.not_authorized"
    redirect_back fallback_location: root_path
  end

  def require_authorization_with_test_modification
    return if current_user.id == @test.user_id

    flash[:danger] = t "tests.show.not_authorized"
    redirect_back fallback_location: root_path
  end

  def test_available?
    subject = Subject.find_by id: params[:subject_id]
    return if subject && subject.questions.count >= subject.question_amount

    flash[:danger] = t "tests.create.not_available"
    redirect_back fallback_location: root_path
  end

  def require_doing_test
    return if @test.doing?

    flash[:danger] = t "tests.has_finished"
    redirect_to root_path
  end

  def require_finished_test
    return unless @test.doing?

    flash[:danger] = t "tests.not_finished"
    redirect_to root_path
  end
end
