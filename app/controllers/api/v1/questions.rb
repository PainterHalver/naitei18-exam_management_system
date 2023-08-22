require "./app/controllers/api/entities/question"

module API
  module V1
    class Questions < Grape::API
      include API::V1::Defaults
      include API::V1::Helpers::PaginationHelper

      before do
        validate_authentication
        require_supervisor
      end

      resource :questions do
        desc "Return all questions"
        params do
          use :pagination
          optional :content_cont, type: String, desc: "Content containing"
          optional :question_type_eq, type: Integer, desc: "Question type"
          optional :subject_id_eq, type: Integer, desc: "Subject ID"
          optional :user_id_eq, type: Integer, desc: "Supervisor ID"
        end

        get "", root: :questions do
          query = Question.newest.includes(:answers).ransack declared(params)
          questions = paginate query.result
          present questions, with: API::Entities::Question
        end
      end

      resource :questions do
        desc "Return a question"
        params do
          requires :id, type: String, desc: "ID of the question"
        end
        get ":id", root: "question" do
          load_question_from_id
          present @question, with: API::Entities::QuestionWithAnswers
        end
      end

      helpers do
        params :create_question do
          requires :content, type: String, desc: "Content of the question"
          requires :question_type, type: Integer,
                   desc: "Question type, 0 for single or 1 for multiple"
          requires :subject_id, type: Integer, desc: "Subject ID"
          requires :answers_attributes, type: Array do
            requires :content, type: String, desc: "Content of the answer"
            requires :is_correct, type: Boolean, desc: "Is correct answer"
          end
        end

        params :update_question do
          requires :id, type: String, desc: "ID of the question"
          optional :content, type: String, desc: "Content of the question"
          optional :question_type, type: Integer,
                   desc: "Question type, 0 for single or 1 for multiple"
          optional :subject_id, type: Integer, desc: "Subject ID"
          optional :answers_attributes, type: Array do
            requires :content, type: String, desc: "Content of the answer"
            requires :is_correct, type: Boolean, desc: "Is correct answer"
          end
        end
      end

      resource :questions do
        desc "Create a question"
        params do
          use :create_question
        end
        post "", root: "question" do
          question = @current_user.questions.build declared(params)
          if question.save
            present question, with: API::Entities::Question
          else
            error!(question.errors.full_messages, 422)
          end
        end
      end

      resource :questions do
        before do
          load_question_from_id
          require_no_ongoing_test
        end
        desc "Update a question"
        params do
          use :update_question
        end
        patch ":id", root: "question" do
          ActiveRecord::Base.transaction do
            @question.answers.delete_all
            @question.update! declared(params)
          end
          present @question, with: API::Entities::Question
        rescue ActiveRecord::RecordInvalid
          error!(@question.errors.full_messages, 422)
        rescue ActiveRecord::Rollback
          error!("Question update failed", 500)
        end
      end

      resource :questions do
        before do
          load_question_from_id
          require_no_ongoing_test
        end
        desc "Delete a question"
        params do
          requires :id, type: String, desc: "ID of the question"
        end
        delete ":id" do
          if @question.destroy
            status :no_content
          else
            error!("Delete question failed", 500)
          end
        end
      end

      helpers do
        include Supervisor::SubjectsHelper

        def load_question_from_id
          @question = Question.find_by id: params[:id]
          return if @question

          error!("Question not found", 404)
        end

        def require_no_ongoing_test
          return unless has_ongoing_test?(@question.subject)

          error!("Subject containing the question still has ongoing test", 400)
        end
      end
    end
  end
end
