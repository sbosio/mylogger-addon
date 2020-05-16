# frozen_string_literal: true

class AddNotNullConstrainsToLogFrames < ActiveRecord::Migration[5.2]
  def change
    reversible do |d|
      d.up { delete_log_frames_with_a_null_reference }
    end
    change_column_null :log_frames, :resource_id, false
    change_column_null :log_frames, :message_count, false
    change_column_null :log_frames, :external_id, false
    add_index :log_frames, :external_id, unique: true
  end

  def delete_log_frames_with_a_null_reference
    LogFrame.where(resource_id: nil).delete_all
  end
end
