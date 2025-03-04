FactoryBot.define do
  factory :subject do
    user {FactoryBot.create(:supervisor)}
    name {Faker::Name.name}
    description {Faker::Lorem.sentence(word_count: 20)}
    question_amount {Faker::Number.between(from: 5, to: 30)}
    pass_score {Faker::Number.between(from: 20, to: 100)}
    test_duration {Faker::Number.between(from: 10, to: 30)}
  end
end
