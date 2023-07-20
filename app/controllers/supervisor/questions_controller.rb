class Supervisor::QuestionsController < Supervisor::SupervisorController
  def new
    @question = Question.new
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

  private

  def question_params
    params.require(:question).permit :content, :question_type, :subject_id,
                                     answers_attributes: [:content, :is_correct]
  end
end
