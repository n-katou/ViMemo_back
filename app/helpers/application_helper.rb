module ApplicationHelper
  def format_duration(seconds)
    minutes = seconds / 60
    seconds = seconds % 60
    hours = minutes / 60
    minutes = minutes % 60

    format("%02d:%02d:%02d", hours, minutes, seconds)
  end
end
