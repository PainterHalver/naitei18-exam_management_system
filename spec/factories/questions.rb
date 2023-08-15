FactoryBot.define do
  factory :question do
    creator {FactoryBot.create(:supervisor)}
    subject
    content {Faker::Lorem.sentence(word_count: 20)}
    question_type {Question.question_types.values.sample}
  end

  factory :single_choice_question, class: Question do
    creator {FactoryBot.create(:supervisor)}
    subject
    content {Faker::Lorem.sentence(word_count: 20)}
    question_type {Question.question_types[:single_choice]}
    answers {build_list(:incorrect_answer, 3) << build(:correct_answer)}
  end

  factory :multiple_choice_question, class: Question do
    creator {FactoryBot.create(:supervisor)}
    subject
    content {Faker::Lorem.sentence(word_count: 20)}
    question_type {Question.question_types[:multiple_choice]}
    answers {
      answers_list = build_list(:correct_answer, 2) << build_list(:incorrect_answer, 2)
      answers_list.flatten
    }
  end
end
