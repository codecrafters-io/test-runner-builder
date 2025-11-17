module CodeFixtures
  repository_root = File.expand_path("../../", __dir__)

  DB = {
    "redis-ruby" => {
      "dockerfile_contents" => File.read(File.join(repository_root, "tests/fixtures/dockerfiles/redis-ruby-3.3.Dockerfile")),
      "buildpack_slug" => "ruby-3.3",
      "code_dir" => File.join(repository_root, "tests/fixtures/redis-ruby-pass-stage-1"),
      "course_slug" => "redis",
      "language_slug" => "ruby"
    },
    "redis-rust" => {
      "dockerfile_contents" => File.read(File.join(repository_root, "tests/fixtures/dockerfiles/redis-rust-1.88.Dockerfile")),
      "buildpack_slug" => "rust-1.88",
      "code_dir" => File.join(repository_root, "tests/fixtures/redis-rust-pass-stage-1"),
      "course_slug" => "redis",
      "language_slug" => "rust"
    },
    "redis-go" => {
      "dockerfile_contents" => File.read(File.join(repository_root, "tests/fixtures/dockerfiles/redis-go-1.24.Dockerfile")),
      "buildpack_slug" => "go-1.24",
      "code_dir" => File.join(repository_root, "tests/fixtures/redis-go-pass-stage-1"),
      "course_slug" => "redis",
      "language_slug" => "go"
    },
    "sqlite-python" => {
      "dockerfile_contents" => File.read(File.join(repository_root, "tests/fixtures/dockerfiles/sqlite-python-3.13.Dockerfile")),
      "buildpack_slug" => "python-3.13",
      "code_dir" => File.join(repository_root, "tests/fixtures/sqlite-python-pass-stage-1"),
      "course_slug" => "sqlite",
      "language_slug" => "python"
    }
  }

  def self.get(code_config_key)
    DB.fetch(code_config_key)
  end
end
