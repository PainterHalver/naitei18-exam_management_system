require "rails_helper"

RSpec.describe API::V1::HealthCheck, type: :request do
  describe "GET /api/v1/health_check2" do
    it "returns status 200" do
      get "/api/v1/health_check"
      expect(response).to have_http_status(200)
    end

    it "returns status ok" do
      get "/api/v1/health_check"
      expect(JSON.parse(response.body)["status"]).to eq("ok")
    end
  end
end
