class Subject < ApplicationRecord
  belongs_to :user, class_name: User.name
  has_many :tests, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_one_attached :image

  scope :newest, ->{order created_at: :desc}
end
