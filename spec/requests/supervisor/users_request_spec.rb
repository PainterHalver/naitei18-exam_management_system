require 'rails_helper'
include SessionsHelper
require "shared_examples"

RSpec.describe Supervisor::UsersController, type: :controller do
  let (:supervisor) {create(:supervisor)}

  describe "GET /users" do
    context "user amount less than or equal to #{Settings.pagination.per_page_10}" do
      before do
        log_in supervisor
        create_list(:user, 5)
        get :index
      end

      it "get all user on 1 page" do
        expect(assigns(:users).length).to eq(6)
      end
    end

    context "user amount more than #{Settings.pagination.per_page_10}" do
      before do
        log_in supervisor
        create_list(:user, 20)
        get :index
      end

      it "user " do
        expect(assigns(:users).length).to eq(10)
      end
    end

    context "fail with not login" do
      before do
        get :index
      end

      it_behaves_like "not login error"

      it_behaves_like "back to login"
    end

    context "fail with not supervisor role" do
      let(:user) {create(:user)}
      before do
        log_in user
        get :index
      end

      it_behaves_like "invalid role for supervisor"
    end
  end

  describe "PATCH /users/:id/deactivate" do
    context "deactivate success" do
      let(:active_user) {create(:user)}
      before do
        log_in supervisor
        patch :deactivate, params: {id: active_user.id}
      end

      it "shoud deactivate the user" do
        expect(assigns(:user).activated).to be_falsy
      end

      it_behaves_like "back to users management page"
    end

    context "fail with not found user" do
      before do
        log_in supervisor
        patch :deactivate, params: {id: -1}
      end

      it_behaves_like "user not found"
    end

    context "fail with not login" do
      let(:active_user) {create(:user)}
      before do
        patch :deactivate, params: {id: active_user.id}
      end

      it_behaves_like "not login error"

      it_behaves_like "back to login"
    end

    context "fail with inlvalid supervisor role" do
      let(:user) {create(:user)}
      let(:active_user) {create(:user)}
      before do
        log_in user
        patch :deactivate, params: {id: active_user.id}
      end

      it_behaves_like "invalid role for supervisor"
    end

    context "faile with deactivate not return true" do
      let(:active_user) {create(:user)}
      before do
        allow_any_instance_of(User).to receive(:deactivate).and_return(false)
        log_in supervisor
        patch :deactivate, params: {id: active_user.id}
      end

      it "inform can not deactivate" do
        expect(flash[:danger]).to eq(I18n.t "account_activation.deactivation_failed")
      end

      it_behaves_like "back to users management page"
    end
  end

  describe "PATCH /users/:id/activate" do
    context "activate success" do
      let(:inactive_user) {create(:deactivated)}
      before do
        log_in supervisor
        patch :activate, params: {id: inactive_user.id}
      end

      it "shoud activate the user" do
        expect(assigns(:user).activated).to be_truthy
      end

      it_behaves_like "back to users management page"
    end

    context "fail with not login" do
      let(:inactive_user) {create(:deactivated)}
      before do
        patch :activate, params: {id: inactive_user.id}
      end

      it_behaves_like "not login error"

      it_behaves_like "back to login"
    end

    context "fail with inlvalid supervisor role" do
      let(:user) {create(:user)}
      let(:inactive_user) {create(:deactivated)}
      before do
        log_in user
        patch :activate, params: {id: inactive_user.id}
      end

      it_behaves_like "invalid role for supervisor"
    end

    context "faile with deactivate not return true" do
      let(:inactive_user) {create(:deactivated)}
      before do
        allow_any_instance_of(User).to receive(:activate).and_return(false)
        log_in supervisor
        patch :activate, params: {id: inactive_user.id}
      end

      it "inform can not deactivate" do
        expect(flash[:danger]).to eq(I18n.t "account_activation.failed")
      end

      it_behaves_like "back to users management page"
    end

    context "fail with not found user" do
      before do
        log_in supervisor
        patch :activate, params: {id: -1}
      end

      it_behaves_like "user not found"
    end
  end

  context "fail with try to activate or deactivate a supervisor" do
    let(:another_supervisor) {create(:supervisor)}
    context "deactivate" do
      before do
        log_in supervisor
        patch :deactivate, params: {id: another_supervisor.id}
      end

      it "inform can not deactivate or active supervisor" do
        expect(flash[:danger]).to eq(I18n.t "no_permission")
      end
    end

    context "activate" do
      before do
        log_in supervisor
        patch :activate, params: {id: another_supervisor.id}
      end

      it "inform can not deactivate or active supervisor" do
        expect(flash[:danger]).to eq(I18n.t "no_permission")
      end
    end
  end
end
