require 'rails_helper'
require "shared_examples"

RSpec.describe PasswordResetsController, type: :controller do
  let(:user) {create(:user)}
  describe "POST /password_resets" do
    context "create success" do
      before do
        post :create, params: {password_reset: {email: user.email}}
      end

      it "sent an email" do
        expect{post :create,
                    params: {password_reset: {email: user.email}}}
              .to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "have a reset digest" do
        expect(assigns(:user)[:reset_digest]).not_to be_nil
      end

      it "inform sending email" do
        expect(flash[:info]).to eq(I18n.t "users.reset_password.begin")
      end

      it_behaves_like "back to login"
    end

    context "fail with user not found by email" do
      before do
        post :create, params: {password_reset: {email: "abcdefgh@gmail.com"}}
      end

      it "inform email not invalid" do
        expect(flash[:danger]).to eq(I18n.t "users.errors.email_invalid")
      end

      it "render again password_forgot page" do
        expect(response).to render_template(:new)
      end
    end
  end

  describe "PATCH /password_resets/:id" do
    let(:user_params) {{user: {password: "123456", password_confirmation: "123456"},
                       email: assigns(:user).email, id: assigns(:user).reset_token}}
    context "reset success" do
      before do
        post :create, params: {password_reset: {email: user.email}}
        patch :update, params: user_params
      end

      it "change the password" do
        expect(assigns(:user).authenticate("123456")).to be_truthy
      end
    end

    context "fail with empty password" do
      before do
        post :create, params: {password_reset: {email: user.email}}
        patch :update, params: {user: {password: nil, password_confirmation: nil},
                                email: assigns(:user).email, id: assigns(:user).reset_token}
      end

      it "make user contains error password empty" do
        expect(assigns(:user).errors.full_messages).to eq(["Password #{I18n.t "users.errors.password_empty"}"])
      end

      it "render again password reset page" do
        expect(response).to render_template(:edit)
      end
    end

    context "fail with not found user" do
      before do
        post :create, params: {password_reset: {email: user.email}}
        patch :update, params: {user: {password: "123456", password_confirmation: "123456"},
                                email: nil, id: assigns(:user).reset_token}
      end

      it "inform not found error" do
        expect(flash[:danger]).to eq(I18n.t "users.errors.not_found")
      end

      it_behaves_like "back to login"
    end

    context "fail with expired link" do
      before do
        post :create, params: {password_reset: {email: user.email}}
        Timecop.freeze(15.minutes.after) do
          patch :update, params: user_params
        end
      end

      it "inform not found error" do
        expect(flash[:danger]).to eq(I18n.t "users.reset_password.expired")
      end

      it "redirect to forgot password page" do
        expect(response).to redirect_to new_password_reset_url
      end
    end

    context "fail with invalid user" do
      before do
        post :create, params: {password_reset: {email: user.email}}
        patch :update, params: {user: {password: "123456", password_confirmation: "123456"},
                                email: assigns(:user).email, id: "abcdefgh"}
      end

      it "inform not invalid user" do
        expect(flash[:danger]).to eq(I18n.t "users.errors.user_invalid")
      end

      it_behaves_like "back to home"
    end

    context "fail with can not update" do
      before do
        post :create, params: {password_reset: {email: user.email}}
        patch :update, params: {user: {password: "1234", password_confirmation: nil},
                                email: assigns(:user).email, id: assigns(:user).reset_token}
      end

      it "render again password reset page" do
        expect(response).to render_template(:edit)
      end
    end
  end
end
