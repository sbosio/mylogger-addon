# frozen_string_literal: true

class CreateResources < ActiveRecord::Migration[5.2]
  def change
    create_table :resources do |t|
      t.string :callback_url, null: false
      t.string :name, null: false
      t.text :grant_code_ciphertext, null: false
      t.datetime :grant_expires_at, null: false
      t.string :grant_type, null: false
      t.text :access_token_ciphertext
      t.string :access_token_expires_at
      t.string :access_token_type
      t.text :refresh_token_ciphertext
      t.jsonb :options, default: "'{}'::jsonb"
      t.string :plan, null: false
      t.string :region
      t.uuid :external_id, null: false, index: {unique: true}
      t.text :log_drain_token, null: false
      t.string :state, default: "pending"

      t.timestamps
    end
  end
end
