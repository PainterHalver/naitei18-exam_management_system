require 'rails_helper'
require "shared_examples"
require "test_prof/recipes/rspec/let_it_be"
include SessionsHelper

RSpec.shared_examples "handle test not found error" do |method, action|
  describe "trying to access a nonexistent test" do
    before do
      user = create(:user)
      log_in user
      send method, action, params: {id: -1}
    end

    it_behaves_like "not found test"
  end
end

RSpec.shared_examples "handle transaction fail" do |commit|
  describe "transaction rollback" do
    before do
      log_in user
      post :create, params: {subject_id: subject.id}

      @request.env['HTTP_REFERER'] = edit_test_path assigns(:test)
      allow_any_instance_of(TestsController).to receive(commit == "Submit" ? :submit_test : :create_detail_answers).and_raise(ActiveRecord::Rollback)

      answers = {}
      assigns[:test].test_questions.includes(question: :answers).each do |test_question|
        answers[test_question.id] = test_question.question.single_choice? ?
                                    {"first_answer_id"=>test_question.question.answers.first.id} :
                                    {"answer_ids"=>["", test_question.question.answers.first.id]}
      end

      params = {"test"=>{"test_question"=>answers}, "commit"=>commit, "id"=>assigns[:test].id}
      patch :update, params: params
    end

    it "inform answers error" do
      expect(flash[:danger]).to eq(I18n.t "tests.do.answer_error")
    end

    it "should turn back" do
      expect(response).to redirect_to request.referer
    end
  end
end

RSpec.describe TestsController, type: :controller do
  let_it_be(:user) {create(:user)}
  let_it_be(:subject) {create(:subject)}
  let_it_be(:time) {(subject.test_duration + 0.1).minutes}
  let_it_be(:single_choice_list) {create_list(:single_choice_question, 20, subject: subject)}
  let_it_be(:multiple_choice_list) {create_list(:multiple_choice_question, 20, subject: subject)}

  describe "POST /create" do
    context "post created success" do
      before do
        log_in user
        post :create, params: {subject_id: subject.id}
      end

      it "test must have enough questions" do
        expect(assigns[:test].questions.count).to eq(subject.question_amount)
      end

      it "test must not have any question 2 times" do
        ids = assigns[:test].questions.select(:id)
        expect(ids.uniq()).to eq(ids)
      end

      it "should create score calculation job" do
        expect(CalculateScoreOvertimeJob).to have_been_enqueued.with(assigns[:test].id)
      end
    end

    context "failed to save test" do
      before do
        allow_any_instance_of(Test).to receive(:save).and_return(false)
        log_in user
        post :create, params: {subject_id: subject.id}
      end

      it "should inform can not create test" do
        expect(flash[:danger]).to eq(I18n.t "tests.errors.questions_fail")
      end

      it "should create a subject to render" do
        expect(assigns[:subject].id).to eq(subject.id)
      end

      it "should render subject page again" do
        expect(response).to render_template "subjects/show"
      end
    end

    context "fail with not login" do
      include_examples "handle not login error", [:post, :create]
    end

    context "fail with not enough question" do
      before do
        log_in user
        another_subject = create(:subject)
        post :create, params: {subject_id: another_subject.id}
      end

      it "inform not enough questions" do
        expect(flash[:danger]).to eq(I18n.t "tests.create.not_available")
      end

      it_behaves_like "back to home"
    end
  end

  describe "GET /tests" do
    context "logged in" do
      before do
        log_in user
        get :index
      end

      it_behaves_like "back to home"
    end

    context "not logged in" do
      include_examples "handle not login error", [:get, :index]
    end
  end

  describe "GET /tests/:id/edit" do
    context "show test success" do
      before do
        log_in user
        post :create, params: {subject_id: subject.id}
        get :edit, params: {id: assigns[:test].id}
      end

      it "create instance variable test_questions" do
        expect(assigns[:test_questions]).to eq(TestQuestion.where("test_id = #{assigns[:test].id}"))
      end
    end

    context "fail with not login" do
      include_examples "handle not login error", [:post, :create]
    end

    context "fail with test not found" do
      include_examples "handle test not found error", [:get, :edit]
    end

    context "fail with test has been completed" do
      include_examples "handle test completed error", [:get, :edit]
    end

    context "fail with not authorization" do
      include_examples "handle unauthorization error", [:get, :edit]
    end
  end

  describe "PATCH /tests/:id" do
    context "successfully saved" do
      before do
        log_in user
        post :create, params: {subject_id: subject.id}
      end

      it "must save the answers" do
        answers = {}
        assigns[:test].test_questions.includes(question: :answers).each do  |test_question|
          answers[test_question.id] = test_question.question.single_choice? ?
                                      {"first_answer_id"=>test_question.question.answers.first.id} :
                                      {"answer_ids"=>["", test_question.question.answers.first.id]}
        end

        params = {"test"=>{"test_question"=>answers}, "commit"=>"save", "id"=>assigns[:test].id}
        patch :update, params: params

        expect(DetailAnswer.all.pluck(:answer_id)).to eq (assigns[:test].test_questions.includes(question: :answers)
                                                                        .map{|test_question| test_question.question.answers.first.id})
      end

      it "have no answers if params is empty" do
        answers = {}
        assigns[:test].test_questions.includes(question: :answers).each do |test_question|
          answers[test_question.id] = test_question.question.single_choice? ? {"first_answer_id"=>""} :
                                                                              {"answer_ids"=>[""]}
        end

        params = {"test"=>{"test_question"=>answers}, "commit"=>"save", "id"=>assigns[:test].id}
        patch :update, params: params

        expect(DetailAnswer.all.count).to eq (0)
      end
    end

    context "successfully submit" do
      before do
        log_in user
        post :create, params: {subject_id: subject.id}
      end

      context "submit the answers" do
        before do
          answers = {}
          assigns[:test].test_questions.includes(question: :answers).each do |test_question|
            answers[test_question.id] = test_question.question.single_choice? ?
                                        {"first_answer_id"=>test_question.question.answers.where(is_correct: true).first.id} :
                                        {"answer_ids"=>["", test_question.question.answers.first.id]}
          end

          params = {"test"=>{"test_question"=>answers}, "commit"=>"Submit", "id"=>assigns[:test].id}
          patch :update, params: params
        end

        it "must save the answers" do
          expect(DetailAnswer.all.pluck(:answer_id)).to eq (assigns[:test].test_questions.includes(question: :answers)
                                                                    .map{|test_question| test_question.question.single_choice? ?
                                                                                         test_question.question.answers.where(is_correct: true).first.id :
                                                                                         test_question.question.answers.first.id})
        end

        it "should have true score" do
          expect(assigns(:test).score).to eq (assigns(:test).test_questions.joins(:question).where("question_type = 0").count)
        end

        it "must have end_time" do
          expect(assigns(:test).end_time).not_to be_nil
        end
      end

      context "submit empty answers" do
        before do
          answers = {}
          assigns[:test].test_questions.includes(question: :answers).each do |test_question|
            answers[test_question.id] = test_question.question.single_choice? ?
                                        {"first_answer_id"=>""} :
                                        {"answer_ids"=>[""]}
          end

          params = {"test"=>{"test_question"=>answers}, "commit"=>"Submit", "id"=>assigns[:test].id}
          patch :update, params: params
        end

        it "the test must have 0 score" do
          expect(assigns[:test].score).to eq(0)
        end
      end

      context "fail with incorrect format of answers" do
        before do
          @request.env['HTTP_REFERER'] = edit_test_path assigns(:test)
          params = {"test"=>{}, "commit"=>"Submit", "id"=>assigns[:test].id}
          patch :update, params: params
        end

        it "should inform answers error" do
          expect(flash[:danger]).to eq(I18n.t "tests.do.post_error")
        end

        it "should turn back" do
          expect(response).to redirect_to request.referer
        end
      end
    end

    context "failed with not login" do
      include_examples "handle not login error", [:patch, :update, {id: -1}]
    end

    context "fail with not authorization" do
      include_examples "handle unauthorization error", [:patch, :update]
    end

    context "fail with test not found" do
      include_examples "handle test not found error", [:patch, :update]
    end

    context "fail with test has been completed" do
      include_examples "handle test completed error", [:patch, :update]
    end

    context "save failed with transaction rollback" do
      include_examples "handle transaction fail", "Save"
    end

    context "submit failed with transaction rollback" do
      include_examples "handle transaction fail", "Submit"
    end
  end

  describe "GET /tests/:id" do
    context "show test success" do
      before do
        log_in user
        post :create, params: {subject_id: subject.id}
        answers = {}
        assigns[:test].test_questions.includes(question: :answers).each do  |test_question|
          answers[test_question.id] = test_question.question.single_choice? ?
                                      {"first_answer_id"=>test_question.question.answers.where(is_correct: true).first.id} :
                                      {"answer_ids"=>["", test_question.question.answers.where(is_correct: false).pluck(:id)].flatten}
        end

        params = {"test"=>{"test_question"=>answers}, "commit"=>"Submit", "id"=>assigns[:test].id}
        patch :update, params: params
        get :show, params: {id: assigns[:test].id}
      end

      it "should create instance variable test_questions" do
        expect(assigns[:test_questions]).to eq(TestQuestion.where("test_id = #{assigns[:test].id}"))
      end
    end

    context "fail with not login" do
      include_examples "handle not login error", [:get, :show, {id: -1}]
    end

    context "fail with test not found" do
      include_examples "handle test not found error", [:get, :show]
    end

    context "fail with not authorization" do
      include_examples "handle unauthorization error", [:get, :show]
    end

    context "fail with test not completed" do
      before do
        log_in user
        test = create(:test, user: user, subject: subject)
        get :show, params: {id: test.id}
      end

      it "inform test not completed yet" do
        expect(flash[:danger]).to eq(I18n.t "tests.not_finished")
      end

      it_behaves_like "back to home"
    end
  end
end
