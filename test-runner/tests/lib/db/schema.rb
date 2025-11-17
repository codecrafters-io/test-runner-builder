ActiveRecord::Schema.define do
  create_table "buildpacks", id: :string, force: :cascade do |t|
    t.string "course_slug", null: false
    t.string "language_slug", null: false
    t.string "slug", null: false
    t.string "processed_dockerfile_contents", null: false
  end

  create_table "repositories", id: :string, force: :cascade do |t|
    t.string "course_slug", null: false
    t.string "language_slug", null: false
    t.string "buildpack_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "test_runs", id: :string, force: :cascade do |t|
    t.string "repository_id", null: false
    t.string "submission_id"
    t.string "commit_sha", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "test_run_results", id: :string, force: :cascade do |t|
    t.string "test_run_id", null: false
    t.string "logs_base64"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "test_runner_builds", id: :string, force: :cascade do |t|
    t.string "test_runner_id", null: false
    t.string "commit_sha" # can be null at the start?
    t.string "status", null: false
    t.string "logs_base64"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "test_runners", id: :string, force: :cascade do |t|
    t.string "repository_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "machine_status", null: false
  end

  create_table "submissions", id: :string, force: :cascade do |t|
    t.string "repository_id", null: false
    t.string "commit_sha", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
