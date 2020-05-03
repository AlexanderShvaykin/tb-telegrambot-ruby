class CreateCourseSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :course_sessions do |t|
      t.string :name
      t.string :icon_url, default: "https://image.flaticon.com/icons/svg/149/149092.svg"
      t.string :bg_url
      t.string :application_status
      t.string :complete_status
      t.string :navigation
      t.string :scenario_mode, default: "standart_learning"
      t.integer :tb_id, null: false
      t.integer :deadline
      t.integer :listeners_count
      t.integer :progress
      t.integer :started_at
      t.integer :changed_at
      t.boolean :can_download
      t.boolean :success
      t.boolean :full_access
      t.boolean :has_certificate
      t.float :rating
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end