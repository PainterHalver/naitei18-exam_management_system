require "rails_helper"
require "shared_examples"
require "test_prof/recipes/rspec/let_it_be"
include SessionsHelper

RSpec.describe "Supervisor::Subjects", type: :request do
  let_it_be(:supervisor) { create(:supervisor) }
  let_it_be(:subject1) { create(:subject) }
  let_it_be(:subject2) { create(:subject) }
  before do
    post login_path, params: {session: {email: supervisor.email,
                                        password: supervisor.password}}
  end

  describe "GET /supervisor/subjects" do
    it "returns http success" do
      get supervisor_subjects_path
      expect(response).to have_http_status(:success)
    end

    it "should have all subjects if total <= #{Settings.pagination.per_page_10}" do
      get supervisor_subjects_path
      expect(assigns(:subjects).length).to eq(Subject.all.size)
    end

    it "should have #{Settings.pagination.per_page_10} subjects if total > #{Settings.pagination.per_page_10}" do
      FactoryBot.create_list(:subject, Settings.pagination.per_page_10)
      get supervisor_subjects_path
      expect(assigns(:subjects).length).to eq(Settings.pagination.per_page_10)
    end
  end

  describe "GET /supervisor/subjects/:id" do
    let!(:question1) { create(:single_choice_question, subject: subject1) }
    it "returns http success" do
      get supervisor_subject_path(subject1)
      expect(response).to have_http_status(:success)
    end

    it "should have all questions if total <= #{Settings.pagination.per_page_10}" do
      get supervisor_subject_path(subject1)
      expect(assigns(:questions).length).to eq(subject1.questions.size)
    end

    it "should have #{Settings.pagination.per_page_10} questions if total > #{Settings.pagination.per_page_10}" do
      FactoryBot.create_list(:single_choice_question, Settings.pagination.per_page_10, subject: subject1)
      get supervisor_subject_path(subject1)
      expect(assigns(:questions).length).to eq(Settings.pagination.per_page_10)
    end
  end

  describe "GET /supervisor/subjects/new" do
    it "returns http success" do
      get new_supervisor_subject_path
      expect(response).to have_http_status(:success)
    end

    it "should have a new subject" do
      get new_supervisor_subject_path
      expect(assigns(:subject)).to be_a_new(Subject)
    end
  end

  describe "POST /supervisor/subjects" do
    context "with valid params" do
      it "should create a new subject" do
        test_subject = build(:subject)
        expect do
          post supervisor_subjects_path, params: {subject: test_subject.attributes}
        end.to change(Subject.with_deleted, :count).by(1)
      end
    end

    context "with invalid params" do
      before do
        post supervisor_subjects_path, params: {subject: {name: ""}}
      end

      it "should render :new template" do
        expect(response).to render_template(:new)
      end

      it "should have errors" do
        expect(assigns(:subject).errors.any?).to eq(true)
      end
    end
  end

  describe "PATCH /supervisor/subjects/:id" do
    let(:patch_subject) { create(:subject) }
    context "with valid params" do
      it "should update subject" do
        patch supervisor_subject_path(patch_subject), params: {subject: {name: "New name"}}
        expect(assigns[:subject].name).to eq("New name")
      end

      it "should flash success message" do
        patch supervisor_subject_path(patch_subject), params: {subject: {name: "New name"}}
        expect(flash[:success]).to eq(I18n.t("supervisor.subjects.update_success"))
      end
    end

    context "with invalid params" do
      before do
        patch supervisor_subject_path(patch_subject), params: {subject: {name: ""}}
      end

      it "should render :edit template" do
        expect(response).to render_template(:edit)
      end

      it "should have errors" do
        expect(assigns(:subject).errors.any?).to eq(true)
      end
    end
  end

  describe "DELETE /supervisor/subjects/:id" do
    let!(:delete_subject) { create(:subject) }

    context "has ongoing test" do
      let!(:test) { create(:ongoing_test, subject: delete_subject) }
      it "should not delete subject" do
        expect do
          delete supervisor_subject_path(delete_subject)
        end.not_to change(Subject.with_deleted, :count)
        expect(assigns[:subject].deleted_at).to eq(nil)
      end

      it "should flash danger message" do
        delete supervisor_subject_path(delete_subject)
        expect(flash[:danger]).to eq(I18n.t("has_ongoing_test"))
      end

      it "should redirect to supervisor_subjects_path" do
        delete supervisor_subject_path(delete_subject)
        expect(response).to redirect_to(supervisor_subjects_path)
      end
    end

    context "has questions" do
      it "should be soft deleted" do
        create(:single_choice_question, subject: delete_subject)
        expect do
          delete supervisor_subject_path(delete_subject)
        end.not_to change(Subject.with_deleted, :count)
        expect(assigns[:subject].deleted_at).not_to eq(nil)
      end
    end

    context "has no questions" do
      it "should be hard deleted" do
        expect do
          delete supervisor_subject_path(delete_subject)
        end.to change(Subject, :count).by(-1)
      end
    end

    context "delete fail" do
      it "should flash danger message" do
        allow_any_instance_of(Subject).to receive(:destroy).and_return(false)
        allow_any_instance_of(Subject).to receive(:destroy_fully!).and_return(false)
        delete supervisor_subject_path(delete_subject)
        expect(flash[:danger]).to eq(I18n.t("supervisor.subjects.destroy_fail"))
      end
    end
  end
end

RSpec.describe Supervisor::SubjectsController, type: :controller do
  describe "GET index" do
    include_examples "requires supervisor", :get,  :index
  end

  describe "GET show" do
    include_examples "requires supervisor", :get,  :show, {id: 1}
  end

  describe "GET new" do
    include_examples "requires supervisor", :get,  :new
  end

  describe "POST create" do
    include_examples "requires supervisor", :post, :create, {subject: {name: "New subject"}}
  end

  describe "GET edit" do
    include_examples "requires supervisor", :get,  :edit, {id: 1}
  end

  describe "PATCH update" do
    include_examples "requires supervisor", :patch, :update, {id: 1}
  end

  describe "DELETE destroy" do
    include_examples "requires supervisor", :delete, :destroy, {id: 1}
  end
end
