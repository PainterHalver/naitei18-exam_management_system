FactoryBot.define do
  factory :user do
    name {Faker::Name.name}
    email {Faker::Internet.email}
    password {Faker::Internet.password}
    is_supervisor {false}
    activated {true}
    activated_at {Time.zone.now}
  end
end
