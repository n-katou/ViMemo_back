# spec/factories/youtube_videos.rb

FactoryBot.define do
  factory :youtube_video do
    title { "Sample Video" }
    description { "Sample Description" }
    published_at { Time.now }
    youtube_id { "dQw4w9WgXcQ" }
    duration { 600 }
    association :user
  end
end
