require "rails_helper"
require "shared_examples"
require "jwt"

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
end
