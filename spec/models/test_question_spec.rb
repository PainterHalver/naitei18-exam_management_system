require 'rails_helper'

RSpec.describe TestQuestion, type: :model do
  describe "#first_answer_id" do
    let(:user) {create(:user)}
    let(:subject) {create(:subject)}
    let(:test) {create(:test, user: user, subject: subject)}

    it "single choice questions have only 1 answer" do
      question = create(:single_choice_question)
      test_question = create(:test_question, question: question, test: test)
      detail_answer = create(:detail_answer, test_question: test_question, answer: Answer.where(is_correct: true).first)

      expect(test_question.first_answer_id).to eq(Answer.where(is_correct: true).first[:id])
    end
  end

  describe "#order_asc_question_ids" do
    let(:subject) {create(:subject)}
    let(:question1) {create(:single_choice_question, subject: subject)}
    let(:question2) {create(:single_choice_question, subject: subject)}
    it "should sort by the asc order of question_id" do
      test = create(:test, subject: subject)

      test_question1 = create(:test_question, test: test, question: question1)
      test_question2 = create(:test_question, test: test, question: question2)
      expect(TestQuestion.order_asc_question_ids).to eq([test_question1, test_question2])
    end
  end

  describe "#by_array_of_ids" do
    it "should select all test_questions match the id in the array" do
      ids = create_list(:test_question_single_choice, rand(1..10)).pluck(:id)

      expect(TestQuestion.by_array_of_ids(ids).pluck(:id)).to eq(ids)
    end
  end
end
