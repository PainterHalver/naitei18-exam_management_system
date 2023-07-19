class User < ApplicationRecord
  has_many :subjects
  has_many :tests, dependent: :destroy
end
