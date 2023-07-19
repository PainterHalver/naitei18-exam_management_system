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
  Subject.create!(user_id: supervisor.id,
               name: name,
               description: description,
               question_amount: 20,
               pass_score: 16,
               test_duration: 20)
end
