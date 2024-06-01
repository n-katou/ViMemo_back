# spec/factories/users.rb

FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { "test@example.com" }
    password { "password" }
    password_confirmation { "password" }
  end
end
