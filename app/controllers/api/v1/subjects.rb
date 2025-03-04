module API
  module V1
    class Subjects < Grape::API
      include API::V1::Defaults
      include API::V1::Helpers::PaginationHelper

      resource :subjects do
        desc "Return all subjects"
        params do
          use :pagination
          optional :name_cont, type: String, desc: "Name containing"
          %w(eq gteq lteq).each do |key|
            optional "question_amount_#{key}", type: Integer,
                     desc: "Amount of questions #{key}"
            optional "pass_score_#{key}", type: Float,
                     desc: "Pass score #{key}"
            optional "test_duration_#{key}", type: Integer,
                     desc: "Duration of the test in minutes #{key}"
          end
        end
        get "", root: :subjects do
          query = Subject.newest.includes(:questions).ransack declared(params)
          subjects = paginate query.result
          present subjects, with: API::Entities::Subject
        end
      end

      resource :subjects do
        desc "Return a subject"
        params do
          requires :id, type: String, desc: "ID of the subject"
        end
        get ":id", root: "subject" do
          load_subject_from_id
          present @subject, with: API::Entities::Subject
        end
      end

      resource :subjects do
        before do
          validate_authentication
          require_supervisor
        end
        desc "Create a subject"
        params do
          requires :name, type: String, desc: "Name of the subject"
          requires :description, type: String,
                   desc: "Description of the subject"
          requires :question_amount, type: Integer, desc: "Amount of questions"
          requires :pass_score, type: Float, desc: "Pass score of the subject"
          requires :test_duration, type: Integer,
                   desc: "Duration of the test in minutes"
        end
        post do
          subject = @current_user.subjects.build declared(params)
          if subject.save
            present subject, with: API::Entities::Subject
          else
            error!(subject.errors.full_messages, :unprocessable_entity)
          end
        end
      end

      resource :subjects do
        before do
          validate_authentication
          require_supervisor
          load_subject_from_id
          require_no_ongoing_test
        end
        desc "Update a subject"
        params do
          requires :id, type: String, desc: "ID of the subject"
          optional :name, type: String, desc: "Name of the subject"
          optional :description, type: String,
                   desc: "Description of the subject"
          optional :question_amount, type: Integer, desc: "Amount of questions"
          optional :pass_score, type: Float, desc: "Pass score of the subject"
          optional :test_duration, type: Integer,
                   desc: "Duration of the test in minutes"
        end
        patch ":id" do
          if @subject.update declared(params, include_missing: false)
            present @subject, with: API::Entities::Subject
          else
            error!(@subject.errors.full_messages, :unprocessable_entity)
          end
        end
      end

      resource :subjects do
        before do
          validate_authentication
          require_supervisor
          load_subject_from_id
          require_no_ongoing_test
        end
        desc "Delete a subject"
        params do
          requires :id, type: String, desc: "ID of the subject"
        end
        delete ":id" do
          flag = if has_no_question?(@subject)
                   @subject.destroy_fully!
                 else
                   @subject.destroy
                 end
          if flag
            status :no_content
          else
            error!("Delete subject failed", 500)
          end
        end
      end

      helpers do
        include Supervisor::SubjectsHelper
        def load_subject_from_id
          @subject = Subject.find_by id: params[:id]
          return if @subject

          error!("Subject not found", 404)
        end

        def require_no_ongoing_test
          return unless has_ongoing_test? @subject

          error!("Subject has ongoing test", 400)
        end
      end
    end
  end
end
