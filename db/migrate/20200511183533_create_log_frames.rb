class CreateLogFrames < ActiveRecord::Migration[5.2]
  def change
    create_table :log_frames do |t|
      t.references :resource, foreign_key: true
      t.integer :message_count
      t.string :external_id
      t.text :frame_content_ciphertext

      t.timestamps
    end
  end
end
