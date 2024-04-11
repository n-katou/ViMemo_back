module NotesHelper
  def edit_path_for(note)
    if note.youtube_video_id.present?
      edit_youtube_video_note_path(note.youtube_video, note)
    elsif note.video_id.present?
      edit_video_note_path(note.video, note)
    else
      root_path
    end
  end

  def delete_path_for(note)
    if note.youtube_video_id.present?
      youtube_video_note_path(note.youtube_video, note)
    elsif note.video_id.present?
      video_note_path(note.video, note)
    else
      root_path
    end
  end

  def back_path
    if @youtube_video.present?
      youtube_video_path(@youtube_video)
    elsif @video.present?
      video_path(@video)
    else
      root_path
    end
  end
end
