require 'rails_helper'

RSpec.describe Test, type: :model do
  let(:user) {create(:user)}
  describe "#completed" do
    it "shoud only pick completed tests" do
      create_list(:finished_test, 5, user: user)
      create_list(:failed_test, 5, user: user)

      expect(Test.completed.count).to eq(10)
    end
  end

  describe "#progressing" do
    it "shoud only pick doing tests" do
      create_list(:test, 5, user: user)

      expect(Test.progressing.count).to eq(5)
    end
  end

  describe "#newest" do
    it "shoud be order by created_at DESC" do
      test1 = create(:test)
      test2 = create(:test)

      expect(Test.newest).to eq([test2, test1])
    end
  end

  describe "validate score" do
    let(:subject) {create(:subject)}
    it "should be failed if score is more than question_amount" do
      test = build(:finished_test, subject: subject)
      test.score = subject.question_amount + 1

      expect(test.save).to be_falsy
    end
  end
end
