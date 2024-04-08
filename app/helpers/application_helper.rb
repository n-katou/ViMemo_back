module ApplicationHelper
  def format_duration(seconds)
    minutes = seconds / 60
    seconds = seconds % 60
    hours = minutes / 60
    minutes = minutes % 60

    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

  def video_timestamp_to_seconds(video_timestamp)
    return 0 unless video_timestamp.present?

    parts = video_timestamp.split(':').map(&:to_i)
    parts.reverse.each_with_index.reduce(0) do |total, (part, index)|
      total + part * (60 ** index)
    end
  end
end
