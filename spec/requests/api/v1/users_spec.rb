require "rails_helper"
require "shared_examples"
require "jwt"
require "test_prof/recipes/rspec/let_it_be"

RSpec.describe API::V1::Users, type: :request do
  describe "PATCH /api/v1/users" do
    let(:user) {create(:user)}
    let(:user_token) {JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256")}
    let(:full_update_params) {{name: "tester", email: "tester@gmail.com",
                               password: 123456, password_confirmation: 123456}}

    context "edit success" do
      before do
        patch "/api/v1/users", params: full_update_params,
                               headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status success"
      include_examples "status code 200"

      it "should inform edit success" do
        expect(JSON.parse(response.body)["data"]["message"]).to eq("update success")
      end

      it "should return user with new info edit" do
        user.reload
        expect(JSON.parse(response.body)["data"]["user"]).to include("email" => user.email, "name" => user.name,
                                                                              "password_digest" => user.password_digest)
      end
    end

    context "edit failed with not login" do
      before do
        patch "/api/v1/users", params: full_update_params
      end

      include_examples "status error"

      include_examples "api error not login"
    end

    context "update failed with unconfirmed password" do
      before do
        patch "/api/v1/users", params: {password: 123456},
                               headers: {Authorization: "Bearer #{user_token}"}
      end

      it "inform password must be confirmed" do
        expect(JSON.parse(response.body)["message"]).to eq("Must confirm your password")
      end
    end

    context "update failed with invalid params" do
      before do
        patch "/api/v1/users", params: {email: "tester", password: 123456, password_confirmation: 123456},
                               headers: {Authorization: "Bearer #{user_token}"}
      end

      it "inform an array of errors" do
        expect(JSON.parse(response.body)["message"]).to be_an_instance_of(Array)
      end
    end
  end

  describe "GET /api/v1/users/:id/tests" do
    let_it_be(:user) {create(:user)}
    let_it_be(:user_token) {JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256")}
    let_it_be(:supervisor) {create(:supervisor)}
    let_it_be(:supervisor_token) {JWT.encode({id: supervisor.id}, ENV["hmac_secret"], "HS256")}
    let_it_be(:user_tests) {
      list = create_list(:test, 5, user: user) << create_list(:finished_test, 5, user: user)
      list.flatten
    }

    context "show success" do
      before do
        get "/api/v1/users/#{user.id}/tests", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status success"
      include_examples "status code 200"

      it "show user's history" do
        expect(JSON.parse(response.body)["data"].size).to eq(10)
      end

      it "order desc created_at" do
        expect(JSON.parse(response.body)["data"].pluck(:id).sort {|a, b| b <=> a}).to eq(JSON.parse(response.body)["data"].pluck(:id))
      end
    end

    context "failed with unauthorized" do
      before do
        other_user = create(:user)
        get "/api/v1/users/#{other_user.id}/tests", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status error"

      it "inform access denied" do
        expect(JSON.parse(response.body)["message"]).to eq("You can not access history")
      end
    end

    context "failed with not login" do
      before do
        get "/api/v1/users/#{user.id}/tests"
      end

      include_examples "status error"
      include_examples "api error not login"
    end

    context "failed with user not_found" do
      before do
        get "/api/v1/users/#{-1}/tests", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status error"

      it "inform user not found" do
        expect(JSON.parse(response.body)["message"]).to eq("User not found")
      end
    end

    context "failed with invalid params" do
      context "negative page or per_page" do
        before do
          get "/api/v1/users/#{user.id}/tests", params: {page: 1, per_page: -1}, headers: {Authorization: "Bearer #{user_token}"}
        end

        it "returns status 400" do
          expect(response).to have_http_status(400)
        end

        it "returns error message" do
          expect(JSON.parse(response.body)["message"]).to eq("One or more parameters are invalid")
        end
      end

      context "page or per_page is not a number" do
        before do
          get "/api/v1/users/#{user.id}/tests", params: {page: "a", per_page: 10}, headers: {Authorization: "Bearer #{user_token}"}
        end

        it "returns status 400" do
          expect(response).to have_http_status(400)
        end

        it "returns error message" do
          expect(JSON.parse(response.body)["message"]).to eq("One or more parameters are invalid")
        end
      end
    end
  end

  describe "PATCH /api/v1/users/:id/activate" do
    let_it_be(:user) {create(:user)}
    let_it_be(:user_token) {JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256")}
    let_it_be(:supervisor) {create(:supervisor)}
    let_it_be(:supervisor_token) {JWT.encode({id: supervisor.id}, ENV["hmac_secret"], "HS256")}

    context "activate success" do
      before do
        inactive_user = create(:deactivated)
        patch "/api/v1/users/#{inactive_user.id}/activate", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status success"
      include_examples "status code 200"

      it "should return user with activaed true" do
        expect(JSON.parse(response.body)["data"]["user"]["activated"]).to be_truthy
      end
    end

    context "failed with not login" do
      before do
        inactive_user = create(:deactivated)
        patch "/api/v1/users/#{inactive_user.id}/activate"
      end

      include_examples "status error"

      include_examples "api error not login"
    end

    context "failed with activate your self" do
      before do
        patch "/api/v1/users/#{supervisor.id}/activate", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status code", 403

      include_examples "error message", "can not activate your self"
    end

    context "failed with activate a supervisor" do
      before do
        another_supervisor = create(:supervisor)
        allow_any_instance_of(User).to receive(:activated?).and_return(false)
        patch "/api/v1/users/#{another_supervisor.id}/activate", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status code", 403

      include_examples "error message", "can not activate a supervisor"
    end

    context "failed with activate an active user" do
      before do
        patch "/api/v1/users/#{user.id}/activate", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status code", 403

      include_examples "error message", "can not activate an active user"
    end

    context "failed with unauthorization" do
      before do
        patch "/api/v1/users/#{user.id}/activate", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status code", 403

      include_examples "error message", "You are not authorized to do this"
    end

    context "failed with can not update" do
      before do
        inactive_user = create(:deactivated)
        allow_any_instance_of(User).to receive(:update).and_return(false)
        patch "/api/v1/users/#{inactive_user.id}/activate", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status code", 422

      it "inform errors trying to update" do
        expect(JSON.parse(response.body)["message"]).to be_an_instance_of(Array)
      end
    end
  end

  describe "PATCH /api/v1/users/:id/deactivate" do
    let_it_be(:user) {create(:user)}
    let_it_be(:user_token) {JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256")}
    let_it_be(:supervisor) {create(:supervisor)}
    let_it_be(:supervisor_token) {JWT.encode({id: supervisor.id}, ENV["hmac_secret"], "HS256")}

    context "deactivate success" do
      before do
        patch "/api/v1/users/#{user.id}/deactivate", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status success"
      include_examples "status code 200"

      it "should return user with activaed true" do
        expect(JSON.parse(response.body)["data"]["user"]["activated"]).to be_falsy
      end
    end

    context "failed with not login" do
      before do
        patch "/api/v1/users/#{user.id}/deactivate"
      end

      include_examples "status error"

      include_examples "api error not login"
    end

    context "failed with deactivate your self" do
      before do
        patch "/api/v1/users/#{supervisor.id}/deactivate", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status code", 403

      include_examples "error message", "can not deactivate your self"
    end

    context "failed with deactivate a supervisor" do
      before do
        another_supervisor = create(:supervisor)
        patch "/api/v1/users/#{another_supervisor.id}/deactivate", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status code", 403

      include_examples "error message", "can not deactivate a supervisor"
    end

    context "failed with deactivate an inactive user" do
      before do
        inactive_user = create(:deactivated)
        patch "/api/v1/users/#{inactive_user.id}/deactivate", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status code", 403

      include_examples "error message", "can not deactivate an inactive user"
    end

    context "failed with unauthorization" do
      before do
        patch "/api/v1/users/#{user.id}/deactivate", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status code", 403

      include_examples "error message", "You are not authorized to do this"
    end

    context "failed with can not update" do
      before do
        allow_any_instance_of(User).to receive(:update).and_return(false)
        patch "/api/v1/users/#{user.id}/deactivate", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status code", 422

      it "inform errors trying to update" do
        expect(JSON.parse(response.body)["message"]).to be_an_instance_of(Array)
      end
    end
  end

  describe "GET /api/v1/users" do
    let_it_be(:supervisor) {create(:supervisor)}
    let_it_be(:supervisor_token) {JWT.encode({id: supervisor.id}, ENV["hmac_secret"], "HS256")}
    let_it_be(:user) {create(:user)}
    let_it_be(:user_token) {JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256")}
    let_it_be(:users) {create_list(:user, 10)}

    context "get all users success" do
      before do
        get "/api/v1/users", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      it "should return all users" do
        expect(JSON.parse(response.body)["data"].size).to eq(12)
      end

      it "should be order desc by created_at" do
        array = users.pluck(:id) << supervisor.id << user.id
        expect(JSON.parse(response.body)["data"].pluck("id")).to eq(array.sort {|a, b| b <=> a})
      end
    end

    context "no users exists" do
      before do
        allow(User).to receive(:newest).and_return([])
        get "/api/v1/users", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      it "should inform if no user exists" do
        expect(JSON.parse(response.body)["data"]["message"]).to eq("no user exists")
      end
    end

    context "get all users success with params" do
      before do
        get "/api/v1/users?page=1&per_page=5", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      it "should return 5 users" do
        expect(JSON.parse(response.body)["data"].size).to eq(5)
      end

      it "should be order desc by created_at" do
        sub_array = users.pluck(:id).sort {|a, b| b <=> a}
        expect(JSON.parse(response.body)["data"].pluck("id")).to eq(sub_array.slice(0, 5))
      end
    end

    context "failed with not login" do
      before do
        get "/api/v1/users?page=1&per_page=5"
      end

      include_examples "api error not login"
    end

    context "failed with unauthorization" do
      before do
        get "/api/v1/users?page=1&per_page=5", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "api error unauthorized"
    end
  end

  describe "GET /api/v1/users/:id" do
    let_it_be(:user) {create(:user)}
    let_it_be(:user_token) {JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256")}
    let_it_be(:supervisor) {create(:supervisor)}
    let_it_be(:supervisor_token) {JWT.encode({id: supervisor.id}, ENV["hmac_secret"], "HS256")}
    let_it_be(:tests) {
      doing = create_list(:test, 5, user: user)
      passed = create_list(:finished_test, 5, user: user)
      failed = create_list(:failed_test, 5, user: user)
      total = doing << passed << failed
      total.flatten
    }

    context "get detail success" do
      before do
        get "/api/v1/users/#{user.id}", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status success"
      include_examples "status code 200"

      it "shouldn't container password_digest" do
        expect(JSON.parse(response.body)["data"]["user"]["password_digest"]).to be_nil
      end

      it "return true user data" do
        expect(JSON.parse(response.body)["data"]["user"]).to include("email" => user.email, "id" => user.id, "name" => user.name)
      end

      it "return bonus data" do
        expect(JSON.parse(response.body)["data"]["detail"]).to include("tests_status" => {"failed" => 5, "passed" => 5, "doing" => 5},
                                                                       "tests_in_progress" => 5, "tests_done" => 10,
                                                                      "tests_in_month" => be_a(Hash), "attened_subjects" => be_a(Hash))
      end
    end

    context "failed with not login" do
      before do
        get "/api/v1/users/#{user.id}"
      end
      include_examples "api error not login"
    end

    context "failed with unauthorization" do
      before do
        another_user = create(:user)
        get "/api/v1/users/#{another_user.id}", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status code", 403
      include_examples "api error unauthorized"
    end

    context "failed with supervisor profile" do
      before do
        get "/api/v1/users/#{supervisor.id}", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status code", 403

      include_examples "error message", "Can not access supervisor's profile"
    end

    context "failed with inactive profile" do
      before do
        inactive_user = create(:deactivated)
        get "/api/v1/users/#{inactive_user.id}", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status code", 403

      include_examples "error message", "Can only see profile of the actives"
    end
  end
end
