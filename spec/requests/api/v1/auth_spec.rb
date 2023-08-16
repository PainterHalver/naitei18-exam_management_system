require "rails_helper"
require "shared_examples"

RSpec.describe API::V1::Auth, type: :request do
  describe "POST /api/v1/login" do
    let(:user) {create(:user)}

    context "login success" do
      before do
        post "/api/v1/auth/login", params: {email: user.email, password: user.password}
      end

      include_examples "status code 201"
      include_examples "status success"

      it "return a token" do
        expect(JSON.parse(response.body)["data"]["jwt_token"]).not_to be_nil
      end
    end

    context "email/password wrong combination" do
      before do
        post "/api/v1/auth/login", params: {email: user.email, password: "1234#{user.password}"}
      end

      include_examples "status error"

      it "should inform user of wrong combination" do
        expect(JSON.parse(response.body)["message"]).to eq("Invalid email/pasword combination")
      end
    end

    context "account not activated" do
      before do
        deactivated_user = create(:deactivated)
        post "/api/v1/auth/login", params: {email: deactivated_user.email, password: deactivated_user.password}
      end

      include_examples "status error"

      it "should inform user of inactivation" do
        expect(JSON.parse(response.body)["message"]).to eq("Account need to be activated")
      end
    end
  end
end
