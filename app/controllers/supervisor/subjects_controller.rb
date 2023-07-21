class Supervisor::SubjectsController < Supervisor::SupervisorController
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

  private

  def subject_params
    params.require(:subject).permit :name, :description, :question_amount,
                                    :pass_score, :test_duration
  end
end
