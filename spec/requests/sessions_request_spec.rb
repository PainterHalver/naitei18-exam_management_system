require 'rails_helper'
include SessionsHelper
require "shared_examples"

RSpec.describe SessionsController, type: :controller do
  describe "Post /login" do
    context "login success" do
      context "activated" do
        let(:user) {create(:user)}
        before do
          post :create, params: {session: {email: user.email, password: user.password}}
        end

        it "should update session with user_id" do
          expect(session[:user_id]).to eq(user.id)
        end

        it "inform login success" do
          unless user.is_supervisor?
            expect(flash[:info]).to eq(I18n.t "login.success")
          end
        end

        it_behaves_like "back to home"
      end

      context "not activated" do
        let(:user) {create(:deactivated)}
        before do
          post :create, params: {session: {email: user.email, password: user.password}}
        end
        it "inform that account need to be activated" do
          expect(flash[:warning]).to eq(I18n.t "login.not_activated")
        end

        it_behaves_like "back to login"
      end
    end

    context "login fail with wrong information" do
      let(:user) {create(:user)}
      before do
        post :create, params: {session: {email: user.email, password: "123456"}}
      end

      it "inform login fail due to wrong infor" do
        expect(flash[:danger]).to eq(I18n.t "login.invalid_email_password_combination")
      end

      it "render login page again" do
        expect(response).to render_template(:new)
      end
    end
  end

  describe "DELETE /logout" do
    context "logout with logged in" do
      let(:user) {create(:user)}
      before do
        post :create, params: {session: {email: user.email, password: user.password}}
        delete :destroy
      end

      it "clear session" do
        expect(session[:user_id]).to be_nil
      end

      it_behaves_like "back to home"
    end

    context "logout without logged in" do
      before do
        delete :destroy
      end

      it_behaves_like "back to home"
    end
  end
end
