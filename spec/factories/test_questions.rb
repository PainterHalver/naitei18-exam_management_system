FactoryBot.define do
  factory :test_question_correct, class: TestQuestion do
    test
    question
    correct {true}
  end

  factory :test_question do
    test
    question
  end

  factory :test_question_single_choice, class: TestQuestion do
    test
    question {create(:single_choice_question)}
  end
end
