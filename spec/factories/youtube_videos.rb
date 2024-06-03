FactoryBot.define do
  factory :youtube_video do
    title { "Sample Video" }
    description { "Sample Description" }
    published_at { Time.now }
    sequence(:youtube_id) { |n| "dQw4w9WgXcQ#{n}" }
    duration { 600 }
    likes_count { 0 }
    notes_count { 0 }
    association :user

    after(:create) do |youtube_video|
      create_list(:note, 2, youtube_video: youtube_video, user: youtube_video.user)
    end
  end
end
