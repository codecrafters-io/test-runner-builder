require_relative "test_helper"

class RunTestsTest < Minitest::Test
  def setup
    DatabaseHelper.clean

    @repository = nil
    @git_repository = nil
    @test_run = nil

    @fake_server_thread ||= Thread.new do
      FakeServer.run!
    end
  end

  def test_complains_when_test_runner_id_is_invalid
    create_and_push_git_repository!("redis-ruby")

    error = assert_raises(RuntimeError) do
      @repository.test_runner.id = "inexistent-test-runner-id"

      RunTestsCommandRunner
        .new(git_repository: @git_repository, repository: @repository)
        .run
    end

    assert_match "test runner not found", error.message
    assert_equal 0, TestRunResult.count
  end

  def test_works_when_no_test_runs_are_found
    create_and_push_git_repository!("redis-ruby")
    script_result = run_script!

    assert_match "\"should_retry\":false", script_result.stdout
    assert_equal 0, TestRunResult.count

    assert_equal "stopped", @repository.test_runner.reload.machine_status
  end

  def test_works_when_test_runs_are_found
    create_and_push_git_repository!("redis-ruby")
    create_test_run!

    run_script!

    assert_equal 1, @test_run.results.count
    assert_equal "success", @test_run.results.first.status, @test_run.results.first.parsed_logs
    assert_equal "stopped", @repository.test_runner.reload.machine_status
  end

  def test_works_when_multiple_test_runs_are_present
    create_and_push_git_repository!("redis-ruby")
    test_run_1 = create_test_run!
    test_run_2 = create_test_run!

    run_script!

    assert_equal 1, test_run_1.results.count
    assert_equal "success", test_run_1.results.first.status, test_run_1.results.first.parsed_logs
    assert_equal 1, test_run_2.results.count
    assert_equal "success", test_run_2.results.first.status, test_run_2.results.first.parsed_logs

    assert_equal "stopped", @repository.test_runner.reload.machine_status
  end

  def test_works_when_codecrafters_yml_is_missing
    create_and_push_git_repository!("redis-ruby")

    commit_sha = @git_repository.commit_changes_to_branch! do |working_dir|
      FileUtils.rm("#{working_dir}/codecrafters.yml")
    end

    create_test_run!(commit_sha: commit_sha)
    run_script!

    assert_equal 1, @test_run.results.count
    assert_equal "failure", @test_run.results.first.status, @test_run.results.first.parsed_logs

    assert_match "Didn't find a codecrafters.yml file", @test_run.results.first.parsed_logs
    assert_equal "stopped", @repository.test_runner.reload.machine_status
  end

  def test_works_when_buildpack_has_changed
    create_and_push_git_repository!("redis-ruby")

    commit_sha = @git_repository.commit_changes_to_branch! do |working_dir|
      codecrafters_yml_path = "#{working_dir}/codecrafters.yml"
      File.write(codecrafters_yml_path, File.read(codecrafters_yml_path).gsub(/ruby-3.3/, "ruby-3.5"))
    end

    create_test_run!(commit_sha: commit_sha)
    run_script!

    assert_equal 1, @test_run.results.count
    assert_equal "failure", @test_run.results.first.status, @test_run.results.first.parsed_logs

    assert_match "Detected changes to buildpack (old: ruby-3.3, new: ruby-3.5)", @test_run.results.first.parsed_logs
    assert_equal "stopped", @repository.test_runner.reload.machine_status
  end

  def test_works_when_precompilation_fails
    create_and_push_git_repository!("redis-rust")

    commit_sha = @git_repository.commit_changes_to_branch! do |working_dir|
      `echo "abcd" > #{working_dir}/src/main.rs`
    end

    create_test_run!(commit_sha: commit_sha)
    run_script!

    assert_equal 1, @test_run.results.count
    assert_equal "failure", @test_run.results.first.status, @test_run.results.first.parsed_logs

    assert_match "code failed to compile", @test_run.results.first.parsed_logs
    assert_equal "stopped", @repository.test_runner.reload.machine_status
  end

  def test_works_when_precompilation_succeeds
    create_and_push_git_repository!("redis-rust")

    create_test_run!
    run_script!

    assert_equal 1, @test_run.results.count
    assert_equal "success", @test_run.results.first.status, @test_run.results.first.parsed_logs
    assert_equal "stopped", @repository.test_runner.reload.machine_status

    assert_match "[compile]", @test_run.results.first.parsed_logs
  end

  def test_detects_dependency_file_changes
    create_and_push_git_repository!("redis-rust")

    commit_sha = @git_repository.commit_changes_to_branch! do |working_dir|
      `echo "" > #{working_dir}/Cargo.toml`
    end

    create_test_run!(commit_sha: commit_sha)
    result = run_script!

    assert_equal 0, @test_run.results.count
    assert_match "Detected changes to Cargo.toml", result.out
    assert_equal "starting", @repository.test_runner.reload.machine_status
  end

  def test_moves_app_cached
    create_and_push_git_repository!("sqlite-python")

    create_test_run!
    run_script!

    assert_equal 1, @test_run.results.count
    assert_equal "success", @test_run.results.first.status, @test_run.results.first.parsed_logs
    assert_equal "stopped", @repository.test_runner.reload.machine_status

    # If /app-cached is not moved, the following line will be present in the logs
    refute_match "Creating a virtualenv", @test_run.results.first.parsed_logs
  end

  def test_works_when_run_sh_is_not_present
    create_and_push_git_repository!("redis-ruby")

    commit_sha = @git_repository.commit_changes_to_branch! do |working_dir|
      FileUtils.mkdir_p("#{working_dir}/.codecrafters")
      FileUtils.cp("#{working_dir}/.codecrafters/run.sh", "#{working_dir}/spawn_redis_server.sh")
      FileUtils.rm("#{working_dir}/.codecrafters/run.sh")
    end

    create_test_run!(commit_sha: commit_sha)
    run_script!

    assert_equal 1, @test_run.results.count
    assert_equal "success", @test_run.results.first.status, @test_run.results.first.parsed_logs
    assert_equal "stopped", @repository.test_runner.reload.machine_status
  end

  def create_test_run!(commit_sha: nil)
    commit_sha ||= @git_repository.head_commit_sha
    @test_run = TestRun.create!(repository_id: @repository.id, id: SecureRandom.uuid, commit_sha: commit_sha)
  end

  def create_and_push_git_repository!(code_fixture_key)
    @code_fixture = CodeFixtures.get(code_fixture_key)
    buildpack = Buildpack.upsert_from_code_fixture!(@code_fixture)
    @repository = Repository.create!(id: SecureRandom.uuid, course_slug: @code_fixture.fetch("course_slug"), language_slug: @code_fixture.fetch("language_slug"), buildpack: buildpack)
    @git_repository = FakeGitRepository.new(@code_fixture.fetch("code_dir"), @repository)
    @git_repository.push_to_git_daemon!
  end

  def run_script!
    @git_repository.set_remote_url(@repository.clone_url)

    RunTestsCommandRunner
      .new(git_repository: @git_repository, repository: @repository)
      .run
  end
end
