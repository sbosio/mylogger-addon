# frozen_string_literal: true

class CreateResources < ActiveRecord::Migration[5.2]
  def change
    create_table :resources do |t|
      t.string :callback_url, null: false
      t.string :name, null: false
      t.uuid :grant_code, null: false
      t.datetime :grant_expires_at, null: false
      t.string :grant_type, null: false
      t.string :oauth_token
      t.string :oauth_refresh_token
      t.string :oauth_token_expires_at
      t.jsonb :options, default: "'{}'::jsonb"
      t.string :plan, null: false
      t.string :region
      t.uuid :external_id, null: false, index: { unique: true }
      t.string :log_drain_token, null: false
      t.string :state, default: 'pending'

      t.timestamps
    end
  end
end
