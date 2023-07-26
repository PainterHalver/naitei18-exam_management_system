class Supervisor::QuestionsController < Supervisor::SupervisorController
  before_action :load_question_by_id, only: %i(edit update)

  def new
    @question = Question.new
    @question.subject = Subject.find_by id: params[:subject_id]
    # De cocoon hien thi san 2 answer
    2.times{@question.answers.build}
  end

  def create
    @question = current_user.questions.new question_params
    if @question.save
      flash[:success] = t "supervisor.questions.create_success"
      redirect_to root_path
    else
      flash.now[:danger] = t "supervisor.questions.create_failed"
      render :new
    end
  end

  def edit; end

  def update
    if @question.update question_params
      flash[:success] = t "supervisor.questions.update_success"
      redirect_to root_path
    else
      render :edit
    end
  end

  private

  def load_question_by_id
    @question = Question.find_by id: params[:id]
    return if @question

    flash[:danger] = t "supervisor.questions.not_found"
    redirect_to root_path
  end

  def question_params
    params.require(:question).permit :content, :question_type, :subject_id,
                                     answers_attributes: [:id,
                                                          :content,
                                                          :is_correct,
                                                          :_destroy]
  end
end
