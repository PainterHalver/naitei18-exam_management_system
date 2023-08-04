require "rails_helper"

RSpec.describe User, type: :model do
  describe "#newest" do
    it "sort by created_at desc" do
      user1 = create(:user)
      user2 = create(:user)

      expect(User.newest).to eq([user2, user1])
    end
  end

  describe "#supervisors" do
    it "get only supervisors" do
      supervisor1 = create(:supervisor)
      supervisor2 = create(:supervisor)

      expect(User.supervisors).to eq([supervisor1, supervisor2])
    end
  end

  describe ".ransackable_associations" do
    it "returns the correct array of associations" do
      expect(User.ransackable_associations).to be_empty
    end
  end

  describe ".ransackable_attributes" do
    it "returns the correct array of attributes" do
      expected_attributes = %w(id name email activated created_at)
      expect(User.ransackable_attributes).to eq(expected_attributes)
    end
  end

  describe ".digest" do
    context "min cost" do
      it "return a hashed string with min cost" do
        random_string = Faker::Lorem.sentence(word_count: 10)
        digest = User.digest(random_string)
        expect(BCrypt::Password.new(digest).is_password? random_string).to be_truthy
      end
    end

    context "not min cost" do
      before do
        allow(ActiveModel::SecurePassword).to receive(:min_cost).and_return(nil)
      end
      it "return a hashed string without min cost" do
        random_string = Faker::Lorem.sentence(word_count: 10)
        digest = User.digest(random_string)
        expect(BCrypt::Password.new(digest).is_password? random_string).to be_truthy
      end
    end
  end

  describe ".new_token" do
    it "return a secure token" do
      random_token = User.new_token
      expect(random_token).to match(/\A[A-Za-z0-9\-_]+\z/)
    end
  end

  describe "#create_reset_digest" do
    let (:user) {create(:user)}
    before do
      user.create_reset_digest
    end

    it "check if it really change the reset digest" do
      expect(user.reset_digest).not_to be_nil
    end

    it "check if reset_send_at change" do
      expect(user.reset_send_at).not_to be_nil
    end

    it "#authenticated?" do
      expect(user.authenticated?("reset", user.reset_token)).to be_truthy
    end

    describe "#send_password_reset_email" do
      it "send an email to reset password" do
        message = user.send_password_reset_email
        expect(message).to be_a Mail::Message
      end
    end

    describe "#password_reset_expired?" do
      it "returns true when reset_send_at is more than 10 minutes ago" do
        reset_send_at = 15.minutes.after

        Timecop.freeze(reset_send_at) do
          expect(user.password_reset_expired?).to eq(true)
        end
      end
    end
  end

  describe "#deactivate" do
    it "make user inactive" do
      user = create(:user)
      user.deactivate

      expect(user.activated).to be_falsy
    end
  end

  describe "#activate" do
    it "activate user" do
      user = create(:deactivated)
      user.activate

      expect(user.activated_at).not_to be_nil
    end
  end
end
