class Supervisor::SubjectsController < Supervisor::SupervisorController
  include Supervisor::SubjectsHelper
  before_action :load_subject_by_id, only: %i(show edit update destroy)
  before_action :require_no_ongoing_test, only: :destroy

  def index
    @q = Subject.newest.includes(:tests).ransack(params[:q])
    @pagy, @subjects = pagy @q.result,
                            items: Settings.pagination.per_page_10
  end

  def show
    @pagy, @questions = pagy @subject.questions.newest,
                             items: Settings.pagination.per_page_10
  end

  def new
    @subject = Subject.new
  end

  def create
    @subject = current_user.subjects.new subject_params
    if @subject.save
      flash[:success] = t "supervisor.subjects.create_success"
      redirect_to supervisor_subjects_path
    else
      render :new
    end
  end

  def edit; end

  def update
    if @subject.update subject_params
      flash[:success] = t "supervisor.subjects.update_success"
      redirect_to supervisor_subjects_path
    else
      render :edit
    end
  end

  def destroy
    flag =
      has_no_question?(@subject) ? @subject.destroy_fully! : @subject.destroy

    if flag
      flash[:success] = t "supervisor.subjects.destroy_success"
    else
      flash[:danger] = t "supervisor.subjects.destroy_fail"
    end
    redirect_to supervisor_subjects_path
  end

  private
  def load_subject_by_id
    @subject = Subject.find_by id: params[:id]
    return if @subject

    flash[:danger] = t "subjects.show.not_found"
    redirect_to supervisor_subjects_path
  end

  def require_no_ongoing_test
    return unless has_ongoing_test? @subject

    flash[:danger] = t "has_ongoing_test"
    redirect_to supervisor_subjects_path
  end

  def subject_params
    params.require(:subject).permit :name, :description, :question_amount,
                                    :pass_score, :test_duration
  end
end
