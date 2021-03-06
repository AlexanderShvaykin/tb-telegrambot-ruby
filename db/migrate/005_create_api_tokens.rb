# frozen_string_literal: true

class CreateApiTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :api_tokens do |t|
      t.string :version
      t.string :api_type
      t.string :grant_type
      t.string :expired_at
      t.string :value
      t.boolean :active, default: false, null: false
      t.references :auth_session, foreign_key: true

      t.timestamps
    end
  end
end
