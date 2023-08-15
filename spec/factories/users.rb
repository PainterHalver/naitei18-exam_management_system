FactoryBot.define do
  factory :user do
    name {Faker::Name.name[...30]}
    email {Faker::Internet.email}
    password {Faker::Internet.password}
    is_supervisor {false}
    activated {true}
    activated_at {Time.zone.now}

    factory :supervisor, class: User do
      is_supervisor {true}
    end

    factory :deactivated, class: User do
      activated {false}
    end
  end
end
