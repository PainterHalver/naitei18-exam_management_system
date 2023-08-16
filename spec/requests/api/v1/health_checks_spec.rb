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
      expect(JSON.parse(response.body)["data"]["status"]).to eq("ok")
    end
  end
end
