require "rails_helper"
require "test_prof/recipes/rspec/let_it_be"
require "shared_examples"
require "jwt"

RSpec.describe API::V1::Questions, type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:supervisor) { create(:supervisor) }
  let_it_be(:subject) { create(:subject, user: supervisor) }
  let_it_be(:questions) { create_list(:single_choice_question, 15, subject: subject, creator: supervisor) }
  let_it_be(:user_token) { JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256") }
  let_it_be(:supervisor_token) { JWT.encode({id: supervisor.id}, ENV["hmac_secret"], "HS256") }

  describe "GET /api/v1/questions" do
    context "without supevisor authentication" do
      before do
        get "/api/v1/questions"
      end

      include_examples "status code", 401
      include_examples "error message", "You need to log in"
    end

    context "with supervisor authentication" do
      context "questions exists" do
        before do
          get "/api/v1/questions", params: {page: 1, per_page: 10},
                                   headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 200
        include_examples "status success"

        it "returns questions" do
          expect(JSON.parse(response.body)["data"].size).to eq(10)
        end
      end

      context "questions does not exist" do
        before do
          get "/api/v1/questions", params: {page: 200, per_page: 10},
                                   headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 200
        include_examples "status success"

        it "returns questions" do
          expect(JSON.parse(response.body)["data"].size).to eq(0)
        end
      end
    end

    context "with invalid params" do
      context "negative page or per_page" do
        before do
          get "/api/v1/questions", params: {page: 1, per_page: -1},
                                   headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 400
        include_examples "error message", "One or more parameters are invalid"
      end
    end

    context "with filter options" do
      context "content containing" do
        before do
          create(:single_choice_question, subject: subject, creator: supervisor, content: "not_gonna_collide")
          get "/api/v1/questions", params: {content_cont: "_gonna_"},
                                   headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 200
        include_examples "status success"

        it "returns questions" do
          expect(JSON.parse(response.body)["data"].size).to eq(1)
        end
      end

      context "question type" do
        context "valid question type" do
          before do
            create(:multiple_choice_question, subject: subject, creator: supervisor)
            get "/api/v1/questions", params: {question_type_eq: 1},
                headers: {"Authorization": "Bearer #{supervisor_token}"}
          end

          include_examples "status code", 200
          include_examples "status success"

          it "returns questions" do
            expect(JSON.parse(response.body)["data"].size).to eq(1)
          end
        end

        context "invalid question type" do
          before do
            get "/api/v1/questions", params: {question_type_eq: 100},
                headers: {"Authorization": "Bearer #{supervisor_token}"}
          end

          include_examples "status code", 400
        end
      end
    end
  end

  describe "GET /api/v1/questions/:id" do
    context "without supervisor authentication" do
      before do
        get "/api/v1/questions/#{questions.first.id}"
      end

      include_examples "status code", 401
      include_examples "error message", "You need to log in"
    end

    context "with supervisor authentication" do
      context "question exists" do
        before do
          get "/api/v1/questions/#{questions.first.id}",
              headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 200
        include_examples "status success"

        it "returns question" do
          expect(JSON.parse(response.body)["data"]["id"]).to eq(questions.first.id)
        end

        it "should also have answers" do
          expect(JSON.parse(response.body)["data"]["answers"].size).to eq(questions.first.answers.size)
        end
      end

      context "question does not exist" do
        before do
          get "/api/v1/questions/100",
              headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 404
        include_examples "error message", "Question not found"
      end
    end
  end

  describe "POST /api/v1/questions" do
    let_it_be(:question) { build_stubbed(:single_choice_question, subject: subject, creator: supervisor) }
    let_it_be(:valid_params) { {
      content: question.content,
      question_type: 0,
      subject_id: subject.id,
      answers_attributes: [
        {content: "answer 1", is_correct: true},
        {content: "answer 2", is_correct: false}
      ]
    } }

    context "without supervisor authentication" do
      before do
        post "/api/v1/questions", params: valid_params
      end

      include_examples "status code", 401
      include_examples "error message", "You need to log in"
    end

    context "with supervisor authentication" do
      context "with valid params" do
        before do
          post "/api/v1/questions", params: valid_params,
                                     headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 201
        include_examples "status success"

        it "returns question" do
          expect(JSON.parse(response.body)["data"]["content"]).to eq(question.content)
        end

        it "creates question" do
          q = Question.find_by(content: question.content)
          expect(q).to be_truthy
          expect(q.answers.size).to eq(2)
        end
      end

      context "with invalid params" do
        before do
          post "/api/v1/questions", params: {content: "content"},
                                     headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 400
        include_examples "error message", "One or more parameters are invalid"
      end

      context "model validation failed" do
        before do
          post "/api/v1/questions", params: valid_params.merge(content: nil),
                                     headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 422
      end
    end
  end

  describe "PATCH /api/v1/questions/:id" do
    let_it_be(:question) { create(:single_choice_question, subject: subject, creator: supervisor) }
    let_it_be(:valid_params) { {
      content: question.content,
      question_type: 0,
      subject_id: subject.id,
      answers_attributes: [
        {content: "answer 1", is_correct: true},
        {content: "answer 2", is_correct: false}
      ]
    } }

    context "without supervisor authentication" do
      before do
        patch "/api/v1/questions/#{question.id}", params: valid_params
      end

      include_examples "status code", 401
      include_examples "error message", "You need to log in"
    end

    context "with supervisor authentication" do
      context "question exists" do
        context "with valid params" do
          before do
            patch "/api/v1/questions/#{question.id}", params: valid_params,
                                                       headers: {"Authorization": "Bearer #{supervisor_token}"}
          end

          include_examples "status code", 200
          include_examples "status success"

          it "returns question" do
            expect(JSON.parse(response.body)["data"]["content"]).to eq(question.content)
          end

          it "updates question" do
            q = Question.find_by(content: question.content)
            expect(q).to be_truthy
            expect(q.answers.size).to eq(2)
          end
        end
      end

      context "question does not exist" do
        before do
          patch "/api/v1/questions/0", params: valid_params,
                                         headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 404
        include_examples "error message", "Question not found"
      end

      context "with invalid params" do
        before do
          patch "/api/v1/questions/#{question.id}", params: {question_type: "non_exist"},
                                                     headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 400
        include_examples "error message", "One or more parameters are invalid"
      end

      context "model validation failed" do
        before do
          patch "/api/v1/questions/#{question.id}", params: valid_params.merge(content: nil),
                                                     headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 422
      end

      context "rolled back" do
        before do
          allow(ActiveRecord::Base).to receive(:transaction).and_raise(ActiveRecord::Rollback)
          patch "/api/v1/questions/#{question.id}", params: valid_params,
                                                     headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 500
        include_examples "error message", "Question update failed"
      end

      context "has ongoing test" do
        before do
          allow_any_instance_of(Supervisor::SubjectsHelper).to receive(:has_ongoing_test?).and_return(true)
          patch "/api/v1/questions/#{question.id}", params: valid_params,
                                                     headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 400
        include_examples "error message", "Subject containing the question still has ongoing test"
      end
    end
  end

  context "DELETE /api/v1/questions/:id" do
    let_it_be(:question) { create(:single_choice_question, subject: subject, creator: supervisor) }

    context "without supervisor authentication" do
      before do
        delete "/api/v1/questions/#{question.id}"
      end

      include_examples "status code", 401
      include_examples "error message", "You need to log in"
    end

    context "with supervisor authentication" do
      context "question does not exist" do
        before do
          delete "/api/v1/questions/0",
                 headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 404
        include_examples "error message", "Question not found"
      end

      context "delete fails" do
        before do
          allow_any_instance_of(Question).to receive(:destroy).and_return(false)
          delete "/api/v1/questions/#{question.id}",
                 headers: {"Authorization": "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 500
        include_examples "error message", "Delete question failed"
      end

      context "question exists" do
        context "has ongoing test" do
          before do
            allow_any_instance_of(Supervisor::SubjectsHelper).to receive(:has_ongoing_test?).and_return(true)
            delete "/api/v1/questions/#{question.id}",
                   headers: {"Authorization": "Bearer #{supervisor_token}"}
          end

          include_examples "status code", 400
          include_examples "error message", "Subject containing the question still has ongoing test"
        end

        context "delete successfully" do
          before :all do
            delete "/api/v1/questions/#{question.id}",
                   headers: {"Authorization": "Bearer #{supervisor_token}"}
          end

          include_examples "status code", 204

          it "soft deletes question" do
            q = Question.with_deleted.find_by(id: question.id)
            expect(q).to be_truthy
            expect(q.deleted_at).not_to eq(nil)
          end
        end
      end
    end
  end
end
