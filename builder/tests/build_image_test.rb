require_relative "test_helper"

require "timeout"

class BuildImageTest < Minitest::Test
  def setup
    DatabaseHelper.clean

    @repository = nil
    @git_repository = nil
    @build = nil

    @fake_server_thread ||= Thread.new do
      FakeServer.run!
    end
  end

  def test_pushes_image
    create_and_push_git_repository!("redis-ruby")

    create_build!
    run_script!

    output = Timeout.timeout(5) { `logstream -url #{@build.local_logstream_url} follow` }

    assert_match(/Build successful/, output)
    assert_equal "success", @build.reload.status
    assert_match(/Build successful/, @build.reload.parsed_logs)
  end

  def test_streams_logs_to_test_run_too
    create_and_push_git_repository!("redis-ruby")

    create_build!
    test_run = TestRun.create!(repository_id: @repository.id, id: SecureRandom.uuid, commit_sha: @build.commit_sha)

    run_script!(test_run: test_run)

    output = Timeout.timeout(5) { `logstream -url #{@build.local_logstream_url} follow` }
    Timeout.timeout(5) { `logstream -url #{test_run.local_logstream_url} run echo ended` }
    test_run_output = Timeout.timeout(5) { `logstream -url #{test_run.local_logstream_url} follow` }

    assert_match(/Build successful/, output)
    assert_match(/Build successful/, test_run_output)
    assert_equal "success", @build.reload.status
    assert_match(/Build successful/, @build.reload.parsed_logs)
  end

  def test_handles_missing_buildpack
    create_and_push_git_repository!("redis-ruby")

    @git_repository.commit_changes_to_branch!(branch: "master") do |working_dir|
      FileUtils.rm("#{working_dir}/codecrafters.yml")
    end

    create_build!
    run_script!

    assert_equal "failure", @build.reload.status

    output = Timeout.timeout(5) { `logstream -url #{@build.local_logstream_url} follow` }
    assert_match(/Didn't find a codecrafters.yml file in your repository/, output)
    assert_match(/Didn't find a codecrafters.yml file in your repository/, @build.reload.parsed_logs)
  end

  def test_build_failures
    create_and_push_git_repository!("redis-rust")

    @git_repository.commit_changes_to_branch!(branch: "master") do |working_dir|
      `echo "abcd" > #{working_dir}/Cargo.toml`
    end

    create_build!
    run_script!

    assert_equal "failure", @build.reload.status

    output = Timeout.timeout(5) { `logstream -url #{@build.local_logstream_url} follow` }

    assert_match(/Build failed/, output)
    assert_match(/Build failed/, @build.reload.parsed_logs)
  end

  def test_build_failures_go
    create_and_push_git_repository!("redis-go")

    @git_repository.commit_changes_to_branch!(branch: "master") do |working_dir|
      # Add an invalid module path to go.mod that will cause a build failure
      `echo "module invalid_#" > #{working_dir}/go.mod`
    end

    create_build!
    run_script!

    assert_equal "failure", @build.reload.status

    output = Timeout.timeout(5) { `logstream -url #{@build.local_logstream_url} follow` }

    assert_match(/Build failed/, output)
    assert_match(/Build failed/, @build.reload.parsed_logs)
    assert_match(/go: malformed module path "invalid_#"/, output)
    assert_match(/go: malformed module path "invalid_#"/, @build.reload.parsed_logs)
  end

  def test_builds_for_specific_commit_sha
    create_and_push_git_repository!("redis-rust")

    old_commit_sha = @git_repository.head_commit_sha

    # Should cause a build failure
    new_commit_sha = @git_repository.commit_changes_to_branch!(branch: "testing") do |working_dir|
      `echo "abcd" > #{working_dir}/Cargo.toml`
    end

    refute_equal old_commit_sha, new_commit_sha # make sure they're different

    create_build!(commit_sha: new_commit_sha)

    script_result = run_script!
    assert_match(/Checking out commit #{new_commit_sha}/, script_result.out)

    assert_equal "failure", @build.reload.status

    output = Timeout.timeout(5) { `logstream -url #{@build.local_logstream_url} follow` }

    assert_match(/Build failed/, output)
    assert_match(/Build failed/, @build.reload.parsed_logs)
  end

  def test_removes_dockerignore_file
    create_and_push_git_repository!("redis-ruby")

    @git_repository.commit_changes_to_branch!(branch: "master") do |working_dir|
      `touch #{working_dir}/.dockerignore`
      `touch #{working_dir}/control.txt`
    end

    create_build!
    run_script!
    stream_output = Timeout.timeout(5) { `logstream -url #{@build.local_logstream_url} follow` }
    
    assert_match(/Build successful/, stream_output)
    assert_equal "success", @build.reload.status
    
    ls_output = `docker run --rm registry.fly.io/test-depot-push:test-runner-tests ls -la /app`
    refute_match(/.dockerignore/, ls_output, ".dockerignore should not exist in the built image")
    assert_match(/control.txt/, ls_output, "control.txt should still exist in the built image")
  end

  def create_build!(commit_sha: nil)
    commit_sha ||= @git_repository.head_commit_sha
    @build = TestRunnerBuild.create!(test_runner: @repository.test_runners.first, id: SecureRandom.uuid, commit_sha: commit_sha)
  end

  def create_and_push_git_repository!(code_fixture_key)
    @code_fixture = CodeFixtures.get(code_fixture_key)
    buildpack = Buildpack.upsert_from_code_fixture!(@code_fixture)
    @repository = Repository.create!(id: SecureRandom.uuid, course_slug: @code_fixture.fetch("course_slug"), language_slug: @code_fixture.fetch("language_slug"), buildpack: buildpack)
    @git_repository = FakeGitRepository.new(@code_fixture.fetch("code_dir"), @repository)
    @git_repository.push_to_git_daemon!
  end

  def run_script!(test_run: nil)
    BuildImageCommandRunner
      .new(git_repository: @git_repository, repository: @repository)
      .run(build: @build, test_run: test_run)
  end
end
