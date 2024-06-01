require 'rails_helper'

RSpec.describe "YoutubeVideos", type: :request do
  describe "GET /api/v1/youtube_videos" do
    let!(:user) { create(:user) }
    let!(:youtube_videos) { create_list(:youtube_video, 3, user: user) }

    it "returns a success response" do
      get api_v1_youtube_videos_path
      expect(response).to have_http_status(:success)
    end

    it "returns paginated youtube videos" do
      get api_v1_youtube_videos_path, params: { page: 1, per_page: 2 }
      expect(response).to have_http_status(:success)
      expect(json['videos'].length).to eq(2)
      expect(json['pagination']['total_pages']).to eq(2)
    end

    it "returns correct video details" do
      get api_v1_youtube_videos_path
      expect(response).to have_http_status(:success)
      video = json['videos'].first
      expect(video['title']).to eq(youtube_videos.first.title)
      expect(video['description']).to eq(youtube_videos.first.description)
      expect(video['published_at'].to_time.utc).to be_within(1.second).of(youtube_videos.first.published_at.utc)
      expect(video['duration']).to eq(youtube_videos.first.duration)
    end
  end
end
