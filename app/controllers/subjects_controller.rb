class SubjectsController < ApplicationController
  before_action :load_subject, except: :index

  def index
    @q = Subject.newest.ransack(params[:q])
    @pagy, @subjects = pagy(@q.result,
                            items: Settings.pagination.per_page_10)
  end

  def show
    @test = @subject.tests.build
  end

  private

  def load_subject
    @subject = Subject.find_by id: params[:id]
    return if @subject

    flash[:danger] = t "subjects.show.not_found"
    redirect_to subjects_path
  end
end
