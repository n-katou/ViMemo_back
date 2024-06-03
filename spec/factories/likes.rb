FactoryBot.define do
  factory :like do
    association :user
    association :likeable, factory: :youtube_video
  end
end
