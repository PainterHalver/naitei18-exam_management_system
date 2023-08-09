FactoryBot.define do
  factory :finished_test, class: Test do
    user
    subject
    start_time {Faker::Time.between(from: DateTime.now - 1, to: DateTime.now)}
    end_time {start_time + subject.test_duration.minutes}
    score {Faker::Number.between(from: subject.question_amount * subject.pass_score / 100, to: subject.question_amount)}
    status {Test.statuses[:passed]}
  end

  factory :failed_test, class: Test do
    user
    subject
    start_time {Faker::Time.between(from: DateTime.now - 1, to: DateTime.now)}
    end_time {start_time + subject.test_duration.minutes}
    score {Faker::Number.between(from: 0, to: subject.question_amount * subject.pass_score / 100 - 1)}
    status {Test.statuses[:failed]}
  end

  factory :test do
    user
    subject
    start_time {Faker::Time.between(from: DateTime.now - 1, to: DateTime.now)}
    end_time {start_time + subject.test_duration.minutes}
  end
end
