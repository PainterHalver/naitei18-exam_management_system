require "rails_helper"
require "test_prof/recipes/rspec/let_it_be"
require "shared_examples"

RSpec.describe API::V1::Subjects, type: :request do
  describe "GET /api/v1/subjects" do
    let_it_be(:subjects) { create_list(:subject, 15) }

    context "without params" do
      before do
        get "/api/v1/subjects"
      end

      include_examples "status code 200"
      include_examples "status success"

      it "returns all subjects" do
        expect(JSON.parse(response.body)["data"].size).to eq(15)
      end
    end

    context "with valid params" do
      context "subjects exists" do
        before do
          get "/api/v1/subjects", params: {page: 1, per_page: 10}
        end

        include_examples "status code 200"
        include_examples "status success"

        it "returns subjects" do
          expect(JSON.parse(response.body)["data"].size).to eq(10)
        end
      end

      context "subjects does not exist" do
        before do
          get "/api/v1/subjects", params: {page: 200, per_page: 10}
        end

        include_examples "status code 200"
        include_examples "status success"

        it "returns subjects" do
          expect(JSON.parse(response.body)["data"].size).to eq(0)
        end
      end
    end

    context "with invalid params" do
      context "negative page or per_page" do
        before do
          get "/api/v1/subjects", params: {page: 1, per_page: -1}
        end

        it "returns status 400" do
          expect(response).to have_http_status(400)
        end

        it "returns error message" do
          expect(JSON.parse(response.body)["message"]).to eq("Invalid parameters")
        end
      end

      context "page or per_page is not a number" do
        before do
          get "/api/v1/subjects", params: {page: "abc", per_page: 10}
        end

        it "returns status 400" do
          expect(response).to have_http_status(400)
        end

        it "returns error message" do
          expect(JSON.parse(response.body)["message"]).to eq("page is invalid")
        end
      end
    end
  end

  describe "GET /api/v1/subjects/:id" do
    let(:subject) { create(:subject) }

    context "when subject exists" do
      before do
        get "/api/v1/subjects/#{subject.id}"
      end

      include_examples "status code 200"
      include_examples "status success"

      it "returns subject" do
        expect(JSON.parse(response.body)["data"]["id"]).to eq(subject.id)
      end
    end

    context "when subject does not exist" do
      it "returns status 404" do
        get "/api/v1/subjects/0"
        expect(response).to have_http_status(404)
      end

      it "returns error message" do
        get "/api/v1/subjects/0"
        expect(JSON.parse(response.body)["message"]).to start_with("Couldn't find Subject with")
      end
    end
  end
end
