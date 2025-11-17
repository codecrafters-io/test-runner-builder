require "bundler/setup"
Bundler.require(:default, :test)

require "zeitwerk"
loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/lib")
loader.push_dir("#{__dir__}/lib/db/models")
loader.setup

require "dotenv/load"

require "active_record"

require "fileutils"
require "minitest/autorun"
require "securerandom"

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: "/tmp/test.db"
)

require_relative "lib/db/schema"

ENV["TEST_RUNNER_REPOSITORY_ROOT"] = File.expand_path("../", __dir__)
