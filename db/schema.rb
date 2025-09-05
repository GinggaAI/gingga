# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_04_161805) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

  create_table "ai_responses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "service_name"
    t.uuid "user_id", null: false
    t.string "ai_model"
    t.string "prompt_version"
    t.jsonb "raw_request"
    t.jsonb "raw_response"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "batch_number"
    t.integer "total_batches"
    t.string "batch_id"
    t.index ["ai_model"], name: "index_ai_responses_on_ai_model"
    t.index ["created_at"], name: "index_ai_responses_on_created_at"
    t.index ["prompt_version"], name: "index_ai_responses_on_prompt_version"
    t.index ["service_name", "created_at"], name: "index_ai_responses_on_service_name_and_created_at"
    t.index ["service_name"], name: "index_ai_responses_on_service_name"
    t.index ["user_id"], name: "index_ai_responses_on_user_id"
  end

  create_table "api_responses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "provider", null: false
    t.string "endpoint", null: false
    t.text "request_data"
    t.text "response_data"
    t.integer "status_code"
    t.integer "response_time_ms"
    t.boolean "success", default: false
    t.string "error_message"
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_api_responses_on_created_at"
    t.index ["provider", "endpoint"], name: "index_api_responses_on_provider_and_endpoint"
    t.index ["success"], name: "index_api_responses_on_success"
    t.index ["user_id", "provider"], name: "index_api_responses_on_user_id_and_provider"
    t.index ["user_id"], name: "index_api_responses_on_user_id"
  end

  create_table "api_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "provider"
    t.string "mode"
    t.text "encrypted_token"
    t.uuid "user_id", null: false
    t.boolean "is_valid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "group_url"
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "audiences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "brand_id", null: false
    t.string "name"
    t.jsonb "demographic_profile", default: {}, null: false
    t.jsonb "interests", default: [], null: false
    t.jsonb "digital_behavior", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_audiences_on_brand_id"
  end

  create_table "avatars", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "avatar_id", null: false
    t.string "name", null: false
    t.string "provider", null: false
    t.string "status", default: "active"
    t.text "preview_image_url"
    t.string "gender"
    t.boolean "is_public", default: false
    t.text "raw_response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["avatar_id", "provider", "user_id"], name: "index_avatars_on_unique_avatar_per_user_provider", unique: true
    t.index ["provider"], name: "index_avatars_on_provider"
    t.index ["status"], name: "index_avatars_on_status"
    t.index ["user_id", "provider"], name: "index_avatars_on_user_id_and_provider"
    t.index ["user_id"], name: "index_avatars_on_user_id"
  end

  create_table "brand_channels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "brand_id", null: false
    t.integer "platform", default: 0, null: false
    t.string "handle"
    t.integer "priority", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id", "platform"], name: "index_brand_channels_on_brand_id_and_platform", unique: true
    t.index ["brand_id"], name: "index_brand_channels_on_brand_id"
  end

  create_table "brands", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "industry", null: false
    t.text "value_proposition"
    t.text "mission"
    t.string "voice", null: false
    t.string "content_language"
    t.string "account_language"
    t.jsonb "subtitle_languages", default: [], null: false
    t.jsonb "dub_languages", default: [], null: false
    t.string "region"
    t.string "timezone"
    t.jsonb "guardrails", default: {"tone_no_go" => [], "banned_words" => [], "claims_rules" => ""}, null: false
    t.jsonb "resources", default: {"kling" => false, "stock" => false, "budget" => false, "editing" => false, "ai_avatars" => false, "podcast_clips" => false}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "slug"], name: "index_brands_on_user_id_and_slug", unique: true
    t.index ["user_id"], name: "index_brands_on_user_id"
  end

  create_table "creas_content_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "creas_strategy_plan_id", null: false
    t.uuid "user_id", null: false
    t.uuid "brand_id", null: false
    t.string "content_id", null: false
    t.string "origin_id"
    t.string "origin_source"
    t.integer "week"
    t.string "scheduled_day"
    t.date "publish_date"
    t.datetime "publish_datetime_local"
    t.string "timezone"
    t.string "content_name"
    t.string "status"
    t.date "creation_date"
    t.string "content_type"
    t.string "platform"
    t.string "aspect_ratio"
    t.string "language"
    t.string "pilar"
    t.string "template"
    t.string "video_source"
    t.text "post_description"
    t.text "text_base"
    t.text "hashtags"
    t.jsonb "subtitles", default: {}, null: false
    t.jsonb "dubbing", default: {}, null: false
    t.jsonb "shotplan", default: {}, null: false
    t.jsonb "assets", default: {}, null: false
    t.jsonb "accessibility", default: {}, null: false
    t.jsonb "meta", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "day_of_the_week", comment: "Suggested day of the week for publishing (Monday, Tuesday, etc.)"
    t.integer "batch_number"
    t.integer "batch_total"
    t.index ["brand_id"], name: "index_creas_content_items_on_brand_id"
    t.index ["content_id"], name: "index_creas_content_items_on_content_id", unique: true
    t.index ["creas_strategy_plan_id", "origin_id"], name: "index_creas_content_items_on_strategy_plan_and_origin_id"
    t.index ["creas_strategy_plan_id"], name: "index_creas_content_items_on_creas_strategy_plan_id"
    t.index ["day_of_the_week"], name: "index_creas_content_items_on_day_of_the_week"
    t.index ["status"], name: "index_creas_content_items_on_status", where: "(status IS NOT NULL)"
    t.index ["user_id"], name: "index_creas_content_items_on_user_id"
  end

  create_table "creas_posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "creas_strategy_plan_id", null: false
    t.string "origin_id"
    t.string "content_name", null: false
    t.string "status", null: false
    t.date "creation_date", null: false
    t.date "publish_date", null: false
    t.string "publish_datetime_local"
    t.string "timezone"
    t.string "content_type", default: "Video", null: false
    t.string "platform", default: "Instagram Reels", null: false
    t.string "aspect_ratio", default: "9:16", null: false
    t.string "language"
    t.jsonb "subtitles", default: {}, null: false
    t.jsonb "dubbing", default: {}, null: false
    t.string "pilar", null: false
    t.string "template", null: false
    t.string "video_source", null: false
    t.text "post_description", null: false
    t.text "text_base", null: false
    t.text "hashtags", null: false
    t.jsonb "shotplan", default: {}, null: false
    t.jsonb "assets", default: {}, null: false
    t.jsonb "accessibility", default: {}, null: false
    t.string "kpi_focus"
    t.string "success_criteria"
    t.string "compliance_check"
    t.jsonb "raw_payload", default: {}, null: false
    t.jsonb "meta", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assets"], name: "index_creas_posts_on_assets", using: :gin
    t.index ["creas_strategy_plan_id"], name: "index_creas_posts_on_creas_strategy_plan_id"
    t.index ["shotplan"], name: "index_creas_posts_on_shotplan", using: :gin
    t.index ["user_id", "origin_id"], name: "index_creas_posts_on_user_id_and_origin_id", unique: true
    t.index ["user_id"], name: "index_creas_posts_on_user_id"
  end

  create_table "creas_strategy_plans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "brand_id", null: false
    t.string "strategy_name"
    t.string "month", null: false
    t.string "objective_of_the_month"
    t.integer "frequency_per_week"
    t.jsonb "monthly_themes", default: [], null: false
    t.jsonb "resources_override", default: {}, null: false
    t.jsonb "content_distribution", default: {}, null: false
    t.jsonb "weekly_plan", default: [], null: false
    t.jsonb "remix_duet_plan", default: {}, null: false
    t.jsonb "publish_windows_local", default: {}, null: false
    t.jsonb "brand_snapshot", default: {}, null: false
    t.jsonb "raw_payload", default: {}, null: false
    t.jsonb "meta", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending"
    t.text "error_message"
    t.index ["brand_id", "month"], name: "index_creas_strategy_plans_on_brand_id_and_month"
    t.index ["brand_id"], name: "index_creas_strategy_plans_on_brand_id"
    t.index ["status"], name: "index_creas_strategy_plans_on_status"
    t.index ["user_id"], name: "index_creas_strategy_plans_on_user_id"
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "brand_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "pricing_info"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id", "name"], name: "index_products_on_brand_id_and_name", unique: true
    t.index ["brand_id"], name: "index_products_on_brand_id"
  end

  create_table "reel_scenes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "reel_id", null: false
    t.string "avatar_id"
    t.string "voice_id"
    t.text "script"
    t.integer "scene_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reel_id"], name: "index_reel_scenes_on_reel_id"
  end

  create_table "reels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "template"
    t.string "video_id"
    t.string "status"
    t.text "preview_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "heygen_video_id"
    t.string "video_url"
    t.string "thumbnail_url"
    t.integer "duration"
    t.string "title"
    t.text "description"
    t.string "category"
    t.string "format"
    t.text "story_content"
    t.string "music_preference"
    t.string "style_preference"
    t.boolean "use_ai_avatar"
    t.text "additional_instructions"
    t.index ["user_id"], name: "index_reels_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "ai_responses", "users"
  add_foreign_key "api_responses", "users"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "audiences", "brands"
  add_foreign_key "avatars", "users"
  add_foreign_key "brand_channels", "brands"
  add_foreign_key "brands", "users"
  add_foreign_key "creas_content_items", "brands"
  add_foreign_key "creas_content_items", "creas_strategy_plans"
  add_foreign_key "creas_content_items", "users"
  add_foreign_key "creas_posts", "creas_strategy_plans"
  add_foreign_key "creas_posts", "users"
  add_foreign_key "creas_strategy_plans", "brands"
  add_foreign_key "creas_strategy_plans", "users"
  add_foreign_key "products", "brands"
  add_foreign_key "reel_scenes", "reels"
  add_foreign_key "reels", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
