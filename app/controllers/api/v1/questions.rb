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
          optional :question_type_eq, type: Integer, desc: "Question type",
                    values: {value: Question.question_types.values,
                             message: "must be in
                             #{Question.question_types.values}"}
          optional :subject_id_eq, type: Integer, desc: "Subject ID",
                    values: {value: Subject.pluck(:id),
                             message: "Subject does not exist"}
          optional :user_id_eq, type: Integer, desc: "Supervisor ID",
                    values: {value: User.supervisors.pluck(:id),
                             message: "Supervisor does not exist"}
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
        def load_question_from_id
          @question = Question.find_by id: params[:id]
          return if @question

          error!("Question not found", 404)
        end
      end
    end
  end
end
