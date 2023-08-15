require "rails_helper"
require "shared_examples"

RSpec.describe API::V1::HealthCheck, type: :request do
  describe "GET /api/v1/health_check" do
    before do
      get "/api/v1/health_check"
    end
    include_examples "status code 200"
    include_examples "status success"

    it "returns status ok" do
      get "/api/v1/health_check"
      expect(JSON.parse(response.body)["status"]).to eq("success")
    end
  end
end
