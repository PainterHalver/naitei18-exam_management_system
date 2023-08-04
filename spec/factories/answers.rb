FactoryBot.define do
  factory :answer do
    question
    content {Faker::Lorem.sentence(word_count: 5)}
    is_correct {Faker::Boolean.boolean}
  end

  factory :correct_answer, class: Answer do
    question
    content {Faker::Lorem.sentence(word_count: 5)}
    is_correct {true}
  end

  factory :incorrect_answer, class: Answer do
    question
    content {Faker::Lorem.sentence(word_count: 5)}
    is_correct {false}
  end
end
