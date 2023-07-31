class TestsController < ApplicationController
  before_action :require_login
  before_action :load_test, only: [:update, :show, :edit]
  before_action :load_test_show, only: [:show]
  before_action :has_authorization_with_test?, only: [:show, :edit, :update]
  before_action :require_doing_test, only: [:edit, :update]
  before_action :require_finished_test, only: [:show]
  before_action :post_data_handle, only: [:update]
  before_action :test_available?, only: [:create]

  def create
    @test = current_user.tests.build(test_params)
    if @test.save
      add_questions_to_test
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
    redirect_back fallback_location: root_path
  end

  def edit
    # Set start_time lan dau tien vao test
    if @test.start_time.nil?
      @test.start_time = Time.zone.now
      @test.save
    end
    @questions = @test.questions.includes(:answers)
  end

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
    @test.update!(status: check_pass, score: score, end_time: Time.zone.now)
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
    if detail_answers.empty? || (DetailAnswer.insert_all! detail_answers)
      flash[:success] = t "tests.do.success"
      redirect_to root_path
    else
      flash[:error] = t "test.do.fail"
      redirect_back fallback_location: root_path
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

  def has_authorization_with_test?
    return if current_user.is_supervisor? ||
              current_user.id = @test.user_id

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
