require "rails_helper"
require "shared_examples"
require "test_prof/recipes/rspec/let_it_be"
include SessionsHelper

RSpec.describe "Supervisor::Questions", type: :request do
  let_it_be(:supervisor) { create(:supervisor) }
  let_it_be(:question1) { create(:single_choice_question) }
  let_it_be(:question2) { create(:single_choice_question) }
  before do
    post login_path, params: {session: {email: supervisor.email,
                                        password: supervisor.password}}
  end

  describe "GET /supervisor/questions" do
    it "returns http success" do
      get supervisor_questions_path
      expect(response).to have_http_status(:success)
    end

    it "should have all questions if total <= #{Settings.pagination.per_page_10}" do
      get supervisor_questions_path
      expect(assigns(:questions).length).to eq(Question.all.size)
    end

    it "should have #{Settings.pagination.per_page_10} questions if total > #{Settings.pagination.per_page_10}" do
      FactoryBot.create_list(:single_choice_question, Settings.pagination.per_page_10)
      get supervisor_questions_path
      expect(assigns(:questions).length).to eq(Settings.pagination.per_page_10)
    end

    context "xlsx format" do
      it "should export all questions" do
        get supervisor_questions_path(format: :xlsx)
        expect(response.headers["Content-Disposition"]).to start_with("attachment; filename=\"questions.xlsx\"")
      end
    end
  end

  describe "GET /supervisor/questions/new" do
    it "returns http success" do
      get new_supervisor_question_path
      expect(response).to have_http_status(:success)
    end

    it "should have a new question" do
      get new_supervisor_question_path
      expect(assigns(:question)).to be_a_new(Question)
    end
  end

  describe "POST /supervisor/questions" do
    context "with valid params" do
      it "should create a new question" do
        expect do
          post supervisor_questions_path, params:
          {question: attributes_for(:single_choice_question,
                                    subject_id: question1.subject.id,
                                    question_type: "single_choice",
                                    answers_attributes: {"0":attributes_for(:incorrect_answer),
                                                         "1":attributes_for(:correct_answer)})}
        end.to change(Question.with_deleted, :count).by(1)
      end
    end

    context "with invalid params" do
      before do
        post supervisor_questions_path, params: {question: {content: ""}}
      end

      it "should render :new template" do
        expect(response).to render_template(:new)
      end

      it "should have errors" do
        expect(assigns(:question).errors.any?).to eq(true)
      end
    end
  end

  context "PATCH /supervisor/questions/:id" do
    context "with valid params" do
      it "should update question" do
        patch supervisor_question_path(question1), params: {question: {content: "content"}}
        expect(question1.reload.content).to eq("content")
      end
    end

    context "with invalid params" do
      before do
        patch supervisor_question_path(question1), params: {question: {content: ""}}
      end

      it "should render :edit template" do
        expect(response).to render_template(:edit)
      end

      it "should have errors" do
        expect(assigns(:question).errors.any?).to eq(true)
      end
    end
  end

  describe "DELETE /supervisor/questions/:id" do
    let_it_be(:question) { create(:single_choice_question) }
    context "success" do
      it "should soft delete the question" do
        expect do
          delete supervisor_question_path(question)
        end.to change(Question, :count).by(-1)
      end

      it "should show flash message" do
        delete supervisor_question_path(question)
        expect(flash[:success]).to eq(I18n.t("supervisor.questions.delete_success"))
      end
    end

    context "failure" do
      it "should not delete the question" do
        allow_any_instance_of(Question).to receive(:destroy).and_return(false)
        expect do
          delete supervisor_question_path(question)
        end.to change(Question, :count).by(0)
      end

      it "should show flash message" do
        allow_any_instance_of(Question).to receive(:destroy).and_return(false)
        delete supervisor_question_path(question)
        expect(flash[:danger]).to eq(I18n.t("supervisor.questions.delete_failed"))
      end
    end
  end
end

RSpec.describe Supervisor::QuestionsController, type: :controller do
  describe "GET index" do
    include_examples "requires supervisor", :get, :index
  end

  describe "GET new" do
    include_examples "requires supervisor", :get, :new
  end

  describe "POST create" do
    include_examples "requires supervisor", :post, :create, {question: {content: "content"}}
  end

  describe "GET edit" do
    include_examples "requires supervisor", :get, :edit, {id: 1}
  end

  describe "PATCH update" do
    include_examples "requires supervisor", :patch, :update, {id: 1}
  end

  describe "DELETE destroy" do
    include_examples "requires supervisor", :delete, :destroy, {id: 1}
  end
end
