class SubjectsController < ApplicationController
  def index
    @pagy, @subjects = pagy(Subject.newest,
                            items: Settings.pagination.per_page_10)
  end
end
