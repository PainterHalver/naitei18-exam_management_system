class Supervisor::SubjectsController < Supervisor::SupervisorController
  def index
    @pagy, @subjects = pagy Subject.newest,
                            items: Settings.pagination.per_page_10
  end

  def new; end

  def create; end
end
