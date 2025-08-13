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

ActiveRecord::Schema[8.0].define(version: 2025_08_12_234259) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

  create_table "api_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "provider"
    t.string "mode"
    t.text "encrypted_token"
    t.uuid "user_id", null: false
    t.boolean "is_valid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "objective_of_the_month", null: false
    t.integer "frequency_per_week", null: false
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
    t.index ["brand_id", "month"], name: "index_creas_strategy_plans_on_brand_id_and_month"
    t.index ["brand_id"], name: "index_creas_strategy_plans_on_brand_id"
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
    t.string "mode"
    t.string "video_id"
    t.string "status"
    t.text "preview_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "heygen_video_id"
    t.string "video_url"
    t.string "thumbnail_url"
    t.integer "duration"
    t.index ["user_id"], name: "index_reels_on_user_id"
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

  add_foreign_key "api_tokens", "users"
  add_foreign_key "audiences", "brands"
  add_foreign_key "brand_channels", "brands"
  add_foreign_key "brands", "users"
  add_foreign_key "creas_posts", "creas_strategy_plans"
  add_foreign_key "creas_posts", "users"
  add_foreign_key "creas_strategy_plans", "brands"
  add_foreign_key "creas_strategy_plans", "users"
  add_foreign_key "products", "brands"
  add_foreign_key "reel_scenes", "reels"
  add_foreign_key "reels", "users"
end
