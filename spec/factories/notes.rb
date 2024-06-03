FactoryBot.define do
  factory :note do
    content { "Sample note content" }
    video_timestamp { "1:23" }
    is_visible { true }
    association :user
    association :youtube_video
  end
end
