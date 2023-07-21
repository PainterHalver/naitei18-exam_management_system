class Supervisor::SubjectsController < Supervisor::SupervisorController
  before_action :load_subject_by_id, only: %i(edit update destroy)

  def index
    @pagy, @subjects = pagy Subject.newest,
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

  def destroy; end

  private
  def load_subject_by_id
    @subject = Subject.find_by id: params[:id]
    return if @subject

    flash[:danger] = t "subjects.show.not_found"
    redirect_to supervisor_subjects_path
  end

  def subject_params
    params.require(:subject).permit :name, :description, :question_amount,
                                    :pass_score, :test_duration
  end
end
