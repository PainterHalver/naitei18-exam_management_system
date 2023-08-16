module API
  module V1
    class Subjects < Grape::API
      include API::V1::Defaults
      include API::V1::Helpers::PaginationHelper

      resource :subjects do
        desc "Return all subjects"
        params do
          use :pagination
        end
        get "", root: :subjects do
          subjects = Subject.newest.includes(:questions)
          subjects = paginate subjects
          present subjects, with: API::Entities::Subject
        end

        desc "Return a subject"
        params do
          requires :id, type: String, desc: "ID of the subject"
        end
        get ":id", root: "subject" do
          subject = Subject.where(id: params[:id]).first!
          present subject, with: API::Entities::Subject
        end
      end
    end
  end
end
