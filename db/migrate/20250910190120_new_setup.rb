class NewSetup < ActiveRecord::Migration[8.0]
  def change

    create_table "group_users", force: :cascade do |t|
      t.integer "group_id"
      t.integer "user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "groups", force: :cascade do |t|
      t.string "name"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "project_users", force: :cascade do |t|
      t.integer "project_id"
      t.integer "user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "admin", default: false
      t.boolean "owner", default: false
      t.string "status"
      t.index ["project_id", "user_id"], name: "index_project_users_on_project_id_and_user_id", unique: true
      t.index ["project_id"], name: "index_project_users_on_project_id"
      t.index ["user_id"], name: "index_project_users_on_user_id"
    end

    create_table "projects", force: :cascade do |t|
      t.string "name", limit: 255
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "title"
      t.string "subtitle"
      t.text "about"
      t.index ["name"], name: "index_projects_on_name", unique: true
    end

    create_table "sessions", force: :cascade do |t|
      t.integer "user_id", null: false
      t.string "ip_address"
      t.string "user_agent"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["user_id"], name: "index_sessions_on_user_id"
    end

    create_table "task_users", force: :cascade do |t|
      t.integer "task_id"
      t.integer "user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "state", limit: 255
      t.integer "node_id"
      t.boolean "admin", default: false
      t.integer "kit_id"
      t.string "kit_oid", limit: 255
      t.index ["task_id", "user_id"], name: "index_task_users_on_task_id_and_user_id", unique: true
      t.index ["task_id"], name: "index_task_users_on_task_id"
      t.index ["user_id"], name: "index_task_users_on_user_id"
    end

    create_table "tasks", force: :cascade do |t|
      t.string "name", limit: 255
      t.integer "project_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "node_class_id"
      t.integer "workflow_id"
      t.text "help"
      t.string "help_video", limit: 255
      t.integer "per_person_kit_limit"
      t.integer "kit_type_id"
      t.integer "check_count"
      t.integer "lock_user_id"
      t.text "token_counting_method"
      t.string "status", limit: 255, default: "active"
      t.integer "language_id"
      t.integer "task_type_id"
      t.datetime "deadline"
      t.integer "cref_id"
      t.integer "fund_id"
      t.bigint "game_variant_id"
      t.text "meta"
      t.integer "data_set_id"
      t.index ["cref_id"], name: "index_tasks_on_cref_id"
      t.index ["fund_id"], name: "index_tasks_on_fund_id"
      t.index ["game_variant_id"], name: "index_tasks_on_game_variant_id"
      t.index ["language_id"], name: "index_tasks_on_language_id"
      t.index ["name", "project_id"], name: "index_tasks_on_name_and_project_id", unique: true
      t.index ["name"], name: "index_tasks_on_name"
      t.index ["project_id"], name: "index_tasks_on_project_id"
      t.index ["task_type_id"], name: "index_tasks_on_task_type_id"
    end

    create_table "users", force: :cascade do |t|
      t.string "email_address", null: false
      t.string "password_digest", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "name"
      t.boolean "admin", default: false
      t.string "activation_digest"
      t.boolean "activated", default: false
      t.datetime "activated_at"
      t.string "reset_digest"
      t.datetime "reset_sent_at"
      t.integer "current_task_user_id"
      t.boolean "anon"
      t.datetime "confirmed_at"
      t.string "invite_digest"
      t.datetime "invite_sent_at"
      t.integer "invite_sent_by"
      t.index ["email_address"], name: "index_users_on_email_address", unique: true
    end

    create_table "versions", force: :cascade do |t|
      t.string "whodunnit"
      t.datetime "created_at"
      t.bigint "item_id", null: false
      t.string "item_type", null: false
      t.string "event", null: false
      t.text "object", limit: 1073741823
      t.text "object_changes", limit: 1073741823
      t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    end

    add_foreign_key "sessions", "users"

  end
end
