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
end
