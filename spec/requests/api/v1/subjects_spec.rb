require "rails_helper"
require "test_prof/recipes/rspec/let_it_be"
require "shared_examples"
require "jwt"

RSpec.describe API::V1::Subjects, type: :request do
  describe "GET /api/v1/subjects" do
    let_it_be(:subjects) { create_list(:subject, 15) }

    context "without params" do
      before do
        get "/api/v1/subjects"
      end

      include_examples "status code", 200
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

        include_examples "status code", 200
        include_examples "status success"

        it "returns subjects" do
          expect(JSON.parse(response.body)["data"].size).to eq(10)
        end
      end

      context "subjects does not exist" do
        before do
          get "/api/v1/subjects", params: {page: 200, per_page: 10}
        end

        include_examples "status code", 200
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
          expect(JSON.parse(response.body)["message"]).to eq("One or more parameters are invalid")
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
          expect(JSON.parse(response.body)["message"]).to eq("One or more parameters are invalid")
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

      include_examples "status code", 200
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
        expect(JSON.parse(response.body)["message"]).to eq("Subject not found")
      end
    end
  end

  describe "POST /api/v1/subjects" do
    let_it_be(:user) { create(:user) }
    let_it_be(:supervisor) { create(:supervisor) }
    let_it_be(:user_token) { JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256") }
    let_it_be(:supervisor_token) { JWT.encode({id: supervisor.id}, ENV["hmac_secret"], "HS256") }

    context "token not exist" do
      before :all do
        subject = build_stubbed(:subject)
        post "/api/v1/subjects", params: subject.attributes
      end

      include_examples "status code", 401
    end

    context "token exist and not supervisor" do
      before :all do
        subject = build_stubbed(:subject)
        post "/api/v1/subjects", params: subject.attributes, headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status code", 403
    end

    context "token exist and supervisor" do
      let_it_be(:subject) { build_stubbed(:subject) }

      context "with valid params" do
        before :all do
          post "/api/v1/subjects", params: subject.attributes, headers: {Authorization: "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 201

        it "returns subject" do
          expect(JSON.parse(response.body)["data"]["name"]).to eq(subject.name)
        end

        it "should create subject" do
          expect(Subject.find_by(name: subject.name)).to be_truthy
        end
      end

      context "with invalid params" do
        before :all do
          subject.name = ""
          post "/api/v1/subjects", params: subject.attributes, headers: {Authorization: "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 422

        it "returns error message" do
          expect(JSON.parse(response.body)["message"]).to eq(["Name can't be blank"])
        end

        it "should not create subject" do
          expect(Subject.find_by(name: subject.name)).to be_falsey
        end
      end
    end
  end
  
  describe "PATCH /api/v1/subjects/:id" do
    let_it_be(:user) { create(:user) }
    let_it_be(:supervisor) { create(:supervisor) }
    let_it_be(:subject) { create(:subject) }
    let_it_be(:user_token) { JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256") }
    let_it_be(:supervisor_token) { JWT.encode({id: supervisor.id}, ENV["hmac_secret"], "HS256") }

    context "token not exist" do
      before :all do
        patch "/api/v1/subjects/#{subject.id}", params: subject.attributes
      end

      include_examples "status code", 401
    end

    context "token exist and not supervisor" do
      before :all do
        patch "/api/v1/subjects/#{subject.id}", params: subject.attributes, headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status code", 403
    end

    context "token exist and supervisor" do
      context "with valid params" do
        before :all do
          subject.name = "new name"
          patch "/api/v1/subjects/#{subject.id}", params: subject.attributes, headers: {Authorization: "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 200

        it "returns subject" do
          expect(JSON.parse(response.body)["data"]["name"]).to eq(subject.name)
        end

        it "should update subject" do
          expect(Subject.find_by(name: subject.name)).to be_truthy
        end
      end

      context "with invalid params" do
        before :all do
          subject.name = ""
          patch "/api/v1/subjects/#{subject.id}", params: subject.attributes, headers: {Authorization: "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 422

        it "returns error message" do
          expect(JSON.parse(response.body)["message"]).to eq(["Name can't be blank"])
        end

        it "should not update subject" do
          expect(Subject.find_by(name: subject.name)).to be_falsey
        end
      end

      context "has onging test" do
        let_it_be(:test) { create(:ongoing_test, subject: subject) }
        let_it_be(:new_subject) {build_stubbed(:subject)}
        before :all do
          patch "/api/v1/subjects/#{subject.id}", params: new_subject.attributes, headers: {Authorization: "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 400

        it "returns error message" do
          expect(JSON.parse(response.body)["message"]).to eq("Subject has ongoing test")
        end

        it "should not update subject" do
          expect(Subject.find_by(name: new_subject.name)).to be_falsey
        end
      end
    end
  end

  describe "DELETE /api/v1/subjects/:id" do
    let_it_be(:user) { create(:user) }
    let_it_be(:supervisor) { create(:supervisor) }
    let_it_be(:subject) { create(:subject) }
    let_it_be(:user_token) { JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256") }
    let_it_be(:supervisor_token) { JWT.encode({id: supervisor.id}, ENV["hmac_secret"], "HS256") }

    context "token not exist" do
      before :all do
        delete "/api/v1/subjects/#{subject.id}"
      end

      include_examples "status code", 401

      it "should not delete subject" do
        s = Subject.find_by(id: subject.id)
        expect(s).to be_truthy
        expect(s.deleted_at).to be_nil
      end
    end

    context "token exist and not supervisor" do
      before :all do
        delete "/api/v1/subjects/#{subject.id}", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status code", 403
    end

    context "token exist and supervisor" do
      context "subject id not exist" do
        before :all do
          delete "/api/v1/subjects/0", headers: {Authorization: "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 404
      end
    end

    context "subject id exist" do
      let_it_be(:delete_subject) { create(:subject) }
      let_it_be(:question) { create(:single_choice_question, subject: delete_subject) }

      context "subject has no questions" do
        before :all do
          delete "/api/v1/subjects/#{subject.id}", headers: {Authorization: "Bearer #{supervisor_token}"}
        end

        include_examples "status code", 204

        it "should hard delete subject" do
          expect(Subject.with_deleted.find_by(id: subject.id)).to be_falsey
        end
      end

      context "subject has questions" do
        context "soft delete fail" do
          before do
            allow_any_instance_of(Subject).to receive(:destroy).and_return(false)
            delete "/api/v1/subjects/#{delete_subject.id}", headers: {Authorization: "Bearer #{supervisor_token}"}
          end

          include_examples "status code", 500

          it "should not delete subject" do
            s = Subject.with_deleted.find_by(id: delete_subject.id)
            expect(s).to be_truthy
            expect(s.deleted_at).to be_nil
          end
        end

        context "subject has ongoing test" do
          let_it_be(:test) { create(:ongoing_test, subject: delete_subject) }
          before :all do
            delete "/api/v1/subjects/#{delete_subject.id}", headers: {Authorization: "Bearer #{supervisor_token}"}
          end

          include_examples "status code", 400

          it "returns error message" do
            expect(JSON.parse(response.body)["message"]).to eq("Subject has ongoing test")
          end

          it "should not delete subject" do
            s = Subject.with_deleted.find_by(id: delete_subject.id)
            expect(s).to be_truthy
            expect(s.deleted_at).to be_nil
          end
        end

        context "soft delete success" do
          before :all do
            delete "/api/v1/subjects/#{delete_subject.id}", headers: {Authorization: "Bearer #{supervisor_token}"}
          end

          include_examples "status code", 204

          it "should soft delete subject" do
            s = Subject.with_deleted.find_by(id: delete_subject.id)
            expect(s).to be_truthy
            expect(s.deleted_at).not_to be_nil
          end
        end
      end
    end
  end
end
