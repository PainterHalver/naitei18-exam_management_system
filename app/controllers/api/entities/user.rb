module API
  module Entities
    class User < Grape::Entity
      unexpose :password_digest
      expose :id, :name, :email, :activated_at,
             :activated, :is_supervisor, :created_at
    end
  end
end
