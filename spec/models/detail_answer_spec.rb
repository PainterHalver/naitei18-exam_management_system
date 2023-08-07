require 'rails_helper'

RSpec.describe DetailAnswer, type: :model do
  describe "#by_test_question_ids" do
    it "select all detail_answers match the test_question_ids array" do
      test_questions = create_list(:test_question_single_choice, rand(1..10))
      array = test_questions.pluck(:id)
      test_questions.each do |i|
        create(:detail_answer, test_question: i, answer: i.question.answers.first)
      end

      expect(DetailAnswer.by_test_question_ids(array).pluck(:test_question_id)).to eq(array)
    end
  end
end
