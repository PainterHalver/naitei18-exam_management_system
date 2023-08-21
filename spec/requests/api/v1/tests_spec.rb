require "rails_helper"
require "shared_examples"
require "jwt"
require "test_prof/recipes/rspec/let_it_be"

RSpec.shared_examples "handle transaction fail" do |commit|
  describe "transaction rollback" do
    before do
      allow(ActiveRecord::Base).to receive(:transaction).and_raise(ActiveRecord::Rollback)
      test = Test.first
      answers = {}
      test.test_questions.includes(question: :answers).each do |test_question|
        answers[test_question.id] = test_question.question.single_choice? ?
                                    {"first_answer_id"=>test_question.question.answers.first.id} :
                                    {"answer_ids"=>["", test_question.question.answers.first.id]}
      end

      params = {"test"=>{"test_question"=>answers}, "commit"=>commit, "id"=>test.id}
      patch "/api/v1/tests/#{test.id}", headers: {Authorization: "Bearer #{user_token}"},
                                        params: params
    end

    include_examples "error message", "Internal server error"
    include_examples "status code", 500
  end
end

RSpec.describe API::V1::Tests, type: :request do
  let_it_be(:user) {create(:user)}
  let_it_be(:user_token) {JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256")}
  let_it_be(:supervisor) {create(:supervisor)}
  let_it_be(:supervisor_token) {JWT.encode({id: supervisor.id}, ENV["hmac_secret"], "HS256")}
  let_it_be(:subject) {create(:subject)}
  let_it_be(:single_choice_list) {create_list(:single_choice_question, 20, subject: subject)}
  let_it_be(:multiple_choice_list) {create_list(:multiple_choice_question, 20, subject: subject)}

  describe "POST :/api/v1/tests" do
    context "create test success" do
      before do
        post "/api/v1/tests", headers: {Authorization: "Bearer #{user_token}"},
                              params: {subject_id: subject.id}
      end

      include_examples "status success"
      include_examples "status code", 201

      it "return the test and it's questions" do
        expect(JSON.parse(response.body)["data"]).to include(
          "score" => 0,
          "status" => "doing",
          "test_content" => all(
            include(
              "question" => a_hash_including(
                "content" => be_a(String),
                "question_type" => be_in(["single_choice", "multiple_choice"]),
                "created_at" => be_a(String),
                "answers_count" => be_a(Integer),
                "answers" => all(
                  a_hash_including(
                    "content" => be_a(String),
                    "is_correct" => be_in([true, false])
                  )
                )
              ),
              "chosen_answers" => []
            )
          )
        )
      end
    end

    context "failed with not login" do
      before do
        post "/api/v1/tests", params: {subject_id: subject.id}
      end

      include_examples "api error not login"
    end

    context "failed with subject not found" do
      before do
        post "/api/v1/tests", headers: {Authorization: "Bearer #{user_token}"},
                              params: {subject_id: -1}
      end

      include_examples "status code", 403

      include_examples "error message", "Subject not exists"
    end

    context "failed with supervisor" do
      before do
        post "/api/v1/tests", headers: {Authorization: "Bearer #{supervisor_token}"},
                              params: {subject_id: subject.id}
      end

      include_examples "status code", 403

      include_examples "error message", "Must be a normal user"
    end

    context "failed with not enough questions" do
      before do
        post "/api/v1/tests", headers: {Authorization: "Bearer #{user_token}"},
                              params: {subject_id: create(:subject).id}
      end

      include_examples "status code", 403

      include_examples "error message", "Not enough questions"
    end

    context "failed with can not create test" do
      before do
        allow(ActiveRecord::Base).to receive(:transaction).and_raise(ActiveRecord::Rollback)
        post "/api/v1/tests", headers: {Authorization: "Bearer #{user_token}"},
                              params: {subject_id: subject.id}
      end

      include_examples "status code", 500
      include_examples "error message", "Internal server error"
    end
  end

  describe "PATCH /api/v1/tests/" do
    context "submit test" do
      before do
        post "/api/v1/tests", headers: {Authorization: "Bearer #{user_token}"},
                              params: {subject_id: subject.id}
      end

      context "submit and calculate score" do
        before do
          test = Test.first
          answers = {}
          test.test_questions.includes(question: :answers).each do  |test_question|
            answers[test_question.id] = test_question.question.single_choice? ?
                                        {"first_answer_id"=>test_question.question.answers.first.id} :
                                        {"answer_ids"=>["", test_question.question.answers.limit(2).pluck(:id)].flatten}
          end

          params = {"test"=>{"test_question"=>answers}, "commit"=>"Submit"}
          patch "/api/v1/tests/#{test.id}", headers: {Authorization: "Bearer #{user_token}"},
                                            params: params
        end

        include_examples "status success"
        include_examples "status code 200"

        it "return true format" do
          expect(JSON.parse(response.body)["data"]).to include(
            "score" => Test.first.questions.where(question_type: :multiple_choice).count,
            "end_time" => be_a(String),
            "test_content" => all(
              include(
                "question" => a_hash_including(
                  "content" => be_a(String),
                  "question_type" => be_in(["single_choice", "multiple_choice"]),
                  "created_at" => be_a(String),
                  "answers_count" => be_a(Integer),
                  "answers" => all(
                    a_hash_including(
                      "id" => be_a(Integer),
                      "content" => be_a(String),
                      "is_correct" => be_in([true, false])
                    )
                  )
                ),
                "chosen_answers" => all(
                  a_hash_including(
                    "id" => be_a(Integer),
                    "content" => be_a(String),
                    "is_correct" => be_in([true, false])
                  )
                ),
                "correct" => be_in([true, false])
              )
            )
          )
        end
      end

      context "save the test" do
        before do
          test = Test.first
          answers = {}
          test.test_questions.includes(question: :answers).each do  |test_question|
            answers[test_question.id] = test_question.question.single_choice? ?
                                        {"first_answer_id"=>test_question.question.answers.first.id} :
                                        {"answer_ids"=>["", test_question.question.answers.limit(2).pluck(:id)].flatten}
          end

          params = {"test"=>{"test_question"=>answers}, "commit"=>"Save"}
          patch "/api/v1/tests/#{test.id}", headers: {Authorization: "Bearer #{user_token}"},
                                            params: params
        end

        include_examples "status success"
        include_examples "status code 200"

        it "return true format" do
          expect(JSON.parse(response.body)["data"]).to include(
            "score" => 0,
            "status" => "doing",
            "test_content" => all(
              include(
                "question" => a_hash_including(
                  "content" => be_a(String),
                  "question_type" => be_in(["single_choice", "multiple_choice"]),
                  "created_at" => be_a(String),
                  "answers_count" => be_a(Integer),
                  "answers" => all(
                    a_hash_including(
                      "content" => be_a(String),
                      "is_correct" => be_in([true, false])
                    )
                  )
                ),
                "chosen_answers" => be_a(Array)
              )
            )
          )
        end
      end

      context "failed with not login" do
        before do
          test = Test.first
          patch "/api/v1/tests/#{test.id}"
        end

        include_examples "status error"
        include_examples "api error not login"
      end

      context "failed with not login" do
        before do
          test = Test.first
          patch "/api/v1/tests/#{test.id}"
        end

        include_examples "status error"
        include_examples "api error not login"
      end

      context "failed with unauthorized" do
        before do
          test = Test.first
          another_user = create(:user);
          token = JWT.encode({id: another_user.id}, ENV["hmac_secret"], "HS256")
          patch "/api/v1/tests/#{test.id}", headers: {Authorization: "Bearer #{token}"}
        end

        include_examples "status code", 403
        include_examples "error message", "can not access this test"
      end

      context "failed with test not found" do
        before do
          patch "/api/v1/tests/-1", headers: {Authorization: "Bearer #{user_token}"}
        end

        include_examples "status code", 404
        include_examples "error message", "test not found"
      end

      context "failed with params not valid" do
        before do
          test = Test.first
          patch "/api/v1/tests/#{test.id}", headers: {Authorization: "Bearer #{user_token}"}
        end

        include_examples "status code", 422
        include_examples "error message", "data not valid"
      end

      context "submit with no answers" do
        before do
          test = Test.first
          answers = {}
          test.test_questions.includes(question: :answers).each do |test_question|
            answers[test_question.id] = test_question.question.single_choice? ?
                                        {"first_answer_id"=>""} :
                                        {"answer_ids"=>[""]}
          end

          patch "/api/v1/tests/#{test.id}", headers: {Authorization: "Bearer #{user_token}"},
                                            params: {"test"=>{"test_question"=>answers}, "commit"=>"Submit"}
        end
        include_examples "status code 200"
        include_examples "status success"

        it "return test with no answers and 0 score" do
          expect(JSON.parse(response.body)["data"]).to include(
            "score" => 0,
            "status" => be_in(["failed", "passed"]),
            "test_content" => all(
              include(
                "question" => a_hash_including(
                  "content" => be_a(String),
                  "question_type" => be_in(["single_choice", "multiple_choice"]),
                  "created_at" => be_a(String),
                  "answers_count" => be_a(Integer),
                  "answers" => all(
                    a_hash_including(
                      "content" => be_a(String),
                      "is_correct" => be_in([true, false])
                    )
                  )
                ),
                "chosen_answers" => []
              )
            )
          )
        end
      end

      context "failed with save rollback" do
        include_examples "handle transaction fail", "Save"
      end

      context "failed with submit rollback" do
        include_examples "handle transaction fail", "Submit"
      end

      context "failed with test not doing" do
        before do
          test = create(:finished_test, user: user)
          patch "/api/v1/tests/#{test.id}", headers: {Authorization: "Bearer #{user_token}"}
        end

        include_examples "status code", 403
        include_examples "error message", "test has finished"
      end

      context "failed with can not update empty test" do
        before do
          allow_any_instance_of(Test).to receive(:update).and_return(false)
          test = Test.first
          answers = {}
          test.test_questions.includes(question: :answers).each do |test_question|
            answers[test_question.id] = test_question.question.single_choice? ?
                                        {"first_answer_id"=>""} :
                                        {"answer_ids"=>[""]}
          end

          patch "/api/v1/tests/#{test.id}", headers: {Authorization: "Bearer #{user_token}"},
                                            params: {"test"=>{"test_question"=>answers}, "commit"=>"Submit"}
        end

        include_examples "status code", 500
        include_examples "error message", "Internal server error"
      end
    end
  end

  describe "GET /api/v1/tests/:id" do
    before do
      post "/api/v1/tests", headers: {Authorization: "Bearer #{user_token}"},
                            params: {subject_id: subject.id}
    end

    context "get test info success" do
      before do
        get "/api/v1/tests/#{Test.first.id}", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status success"
      include_examples "status code 200"

      it "return true format" do
        expect(JSON.parse(response.body)["data"]).to include(
          "test_content" => all(
            include(
              "question" => a_hash_including(
                "content" => be_a(String),
                "question_type" => be_in(["single_choice", "multiple_choice"]),
                "created_at" => be_a(String),
                "answers_count" => be_a(Integer),
                "answers" => all(
                  a_hash_including(
                    "content" => be_a(String),
                    "is_correct" => be_in([true, false])
                  )
                )
              ),
              "chosen_answers" => be_a(Array)
            )
          )
        )
      end
    end

    context "failed with not login" do
      before do
        test = Test.first
        get "/api/v1/tests/#{test.id}"
      end

      include_examples "status error"
      include_examples "api error not login"
    end

    context "failed with user unauthorized" do
      before do
        test = create(:test, user: create(:user))
        get "/api/v1/tests/#{test.id}", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status error"
      include_examples "status code", 403

      include_examples "error message", "can not access this test"
    end

    context "failed with test not found" do
      before do
        get "/api/v1/tests/-1", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status error"
      include_examples "status code", 404

      include_examples "error message", "test not found"
    end

    context "failed with supervisor access doing test" do
      before do
        test = Test.first
        get "/api/v1/tests/#{test.id}", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status error"
      include_examples "status code", 403

      include_examples "error message", "can not access this test"
    end
  end
end
