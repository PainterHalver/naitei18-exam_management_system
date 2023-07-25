# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

subjects = ["Công nghệ phần mềm", "Ngôn ngữ lập trình C++ (Cơ bản)", "Ruby Association Certified Ruby Programmer Gold (Ruby gold)",
            "Ngôn ngữ lập trình Java (Nâng cao)", "Ngôn ngữ lập trình Java (Cơ bản)", "Hệ quản trị cơ sở dữ liệu", "Python Essentials",
            "Cấu trúc dữ liệu và Giải thuật nâng cao", "Mạng máy tính", "Nguyên lý hệ điều hành", "TypeScript cơ bản", "Kiến trúc máy tính",
            "Introduction to Data Structures and Algorithms", "Project Management Professional (PMP)", "Machine Learning Basic", "CSS Advanced",
            "Client-side Javascript", "Professional Scrum Master I (PSM-I)", "CSS Basic", "HTML for Beginners", "PHP for Web Developers",
            "Javascript Core", "Secure Infrastructure", "Introduction to Artificial Intelligence", "Vue.js Essentitals", "React.js Essentitals",
            "Secure Coding Training", "Blockchain Fundamentals", "Docker Certified Associate", "Vim Basic", "Git Essentials", "Laravel Essentials",
            "Fundamental Information Technology Engineer Examination (FE)"]

supervisor = User.create!(name: "Example Supervisor",
  email: "example@railstutorial.org",
  password: "foobar",
  password_confirmation: "foobar",
  is_supervisor: true,
  activated: true,
  activated_at: Time.zone.now)

subjects.each do |subject|
  name = subject
  description = "awesome project"
  item = Subject.create!(user_id: supervisor.id,
               name: name,
               description: description,
               question_amount: 20,
               pass_score: 80,
               test_duration: 20)

  20.times do |n|
    correct = rand(1..4)
    query = [1,2,3,4].map {|i| {
      is_correct: correct == i ? true : false,
      content: "Dap an #{i}",
    }}

    question = item.questions.create!({
      content: Faker::Lorem.sentence(word_count: 20),
      user_id: supervisor.id,
      question_type: Question.question_types[:single_choice],
      answers_attributes: query
    })
  end

  10.times do |n|
    num = rand(2..4)
    correct = [1,2,3,4].sample(num);
    query = [1,2,3,4].map {|i| {
      is_correct: correct.include?(i) ? true : false,
      content: "Dap an #{i}",
    }}
    question = item.questions.create!({
      content: Faker::Lorem.sentence(word_count: 20),
      user_id: supervisor.id,
      question_type: Question.question_types[:multiple_choice],
      answers_attributes: query
    })
  end
end

5.times do |n|
  name = "user#{n+1}"
  email = "example-#{n+1}@railstutorial.org"
  password = "foobar"
  User.create!(name: name,
    email: email,
    password: password,
    password_confirmation: password,
    activated: true,
    activated_at: Time.zone.now)
end
