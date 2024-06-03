require 'rails_helper'

RSpec.describe "YoutubeVideos", type: :request do
  describe "GET /api/v1/youtube_videos" do
    let!(:user) { create(:user) }
    let!(:youtube_videos) { create_list(:youtube_video, 3, user: user) }

    before do
      youtube_videos.each do |video|
        create_list(:note, 2, youtube_video: video, user: user)
        create_list(:like, 2, likeable: video, user: user)
      end
    end

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

    it "returns videos sorted by likes" do
      youtube_videos.each_with_index do |video, index|
        create_list(:like, index + 1, likeable: video, user: user)
      end

      get api_v1_youtube_videos_path, params: { sort: 'likes_desc' }
      expect(response).to have_http_status(:success)
      sorted_videos = json['videos']
      expect(sorted_videos.first['likes_count']).to be >= sorted_videos.second['likes_count']
    end

    it "returns videos filtered by title" do
      filtered_title = youtube_videos.first.title
      get api_v1_youtube_videos_path, params: { q: { title_cont: filtered_title } }
      expect(response).to have_http_status(:success)
      filtered_videos = json['videos']
      expect(filtered_videos.count { |video| video['title'].include?(filtered_title) }).to eq(1)
    end

    it "returns videos with user information" do
      get api_v1_youtube_videos_path
      expect(response).to have_http_status(:success)
      video = json['videos'].first
      expect(video['user']['id']).to eq(user.id)
      expect(video['user']['name']).to eq(user.name)
    end

    it "returns videos with notes" do
      get api_v1_youtube_videos_path
      expect(response).to have_http_status(:success)
      video = json['videos'].first
      expect(video['notes']).not_to be_nil
      expect(video['notes'].length).to eq(2)
    end
  end
end
