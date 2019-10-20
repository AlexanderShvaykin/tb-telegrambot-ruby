class CreateCourseSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :course_sessions do |t|
      t.string :instance
      t.string :course_name, null: false
      t.string :icon_url, default: "https://image.flaticon.com/icons/svg/149/149092.svg"
      t.string :bg_url
      t.string :deadline
      t.integer :period
      t.integer :listeners_count
      t.integer :progress, null: false
      t.timestamp :started_at
      t.boolean :can_download
      t.boolean :success
      t.boolean :full_access
      t.string :application_status
      t.string :complete_status, null: false
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end