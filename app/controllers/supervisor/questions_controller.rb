class Supervisor::QuestionsController < Supervisor::SupervisorController
  include Supervisor::QuestionsHelper
  before_action :load_question_by_id, only: %i(edit update destroy)

  def index
    @query = Question.newest.ransack params[:q]
    @pagy, @questions = pagy @query.result,
                             items: Settings.digit.length_10
    respond_to do |format|
      format.html
      format.xlsx do
        p = QuestionsExporter.new(Question.newest.includes(:answers)).call
        send_data p.to_stream.read, filename: "questions.xlsx"
      end
    end
  end

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
      redirect_back fallback_location: supervisor_root_path
    else
      flash.now[:danger] = t "supervisor.questions.create_failed"
      render :new
    end
  end

  def edit; end

  def update
    if @question.update question_params
      flash[:success] = t "supervisor.questions.update_success"
      redirect_back fallback_location: supervisor_root_path
    else
      render :edit
    end
  end

  def destroy
    if @question.destroy
      flash[:success] = t "supervisor.questions.delete_success"
    else
      flash[:danger] = t "supervisor.questions.delete_failed"
    end
    redirect_back fallback_location: supervisor_root_path
  end

  private

  def load_question_by_id
    @question = Question.find_by id: params[:id]
    return if @question

    flash[:danger] = t "supervisor.questions.not_found"
    redirect_to supervisor_root_path
  end

  def question_params
    params.require(:question).permit :content, :question_type, :subject_id,
                                     answers_attributes: [:id,
                                                          :content,
                                                          :is_correct,
                                                          :_destroy]
  end
end
