require "sinatra/base"

class FakeServer < Sinatra::Base
  set :port, 6331
  set :bind, "0.0.0.0"

  error do
    content_type :json
    status 500

    {
      error: env["sinatra.error"].message,
      backtrace: env["sinatra.error"].backtrace.join("\n")
    }.to_json
  end

  get "/" do
    "hello"
  end

  # --- Public Interface Starts ---

  post "/services/test_runner/create_submission" do
    halt 400, {error: "invalid content type"}.to_json unless request.content_type == "application/json"
    json = JSON.parse(request.body.read)

    repository_id = json.fetch("repository_id")
    repository = Repository.find_by(id: repository_id) # should actually use secret_id

    if !repository
      halt 400, "repository not found"
    end

    if repository.id == "no-paid-access"
      halt 200, {is_error: true, error_message: "This stage requires a CodeCrafters membership"}.to_json
    end

    submission = Submission.create!(commit_sha: json.fetch("commit_sha"), repository: repository)
    test_run = submission.test_runs.create!(commit_sha: json.fetch("commit_sha"), repository: repository)

    Timeout.timeout(5) { `logstream -url #{test_run.local_logstream_url} run echo test-run-success` }

    build = TestRunnerBuild.where(test_runner: repository.test_runners, status: "in_progress").first

    halt 200, {
      id: submission.id,
      actions: SubmissionTestRunnerActionsBuilder.build(submission: submission, test_run: test_run, pending_build: build).map(&:as_json_for_test_runner)
    }.to_json
  end

  get "/services/test_runner/fetch_submission" do
    _submission = Submission.find(params.fetch("submission_id"))

    halt 200, {status: "success"}.to_json
  end

  get "/services/test_runner/fetch_test_runner_build" do
    test_runner_build = TestRunnerBuild.find_by_id(params.fetch("test_runner_build_id"))

    if !test_runner_build
      puts "build not found, id: #{params.fetch("id")}"
      halt 404, {error: "build not found"}.to_json
    end

    halt 200, {status: test_runner_build.status}.to_json
  end

  post "/services/test_runner/finalize_test_runner_build" do
    halt 400, {error: "invalid content type"}.to_json unless request.content_type == "application/json"

    json = JSON.parse(request.body.read)

    build = TestRunnerBuild.find_by(id: json.fetch("test_runner_build_id"))
    halt 404, {error: "build not found"}.to_json if build.nil?

    build.update!(status: json.fetch("status"), logs_base64: json.fetch("logs_base64"))
  end

  post "/services/test_runner/reserve_test_run" do
    test_runner_id = params.fetch("test_runner_id")
    halt 400, {error: "test_runner_id is required"}.to_json if test_runner_id.strip.empty?

    test_runner = TestRunner.find_by(id: test_runner_id)
    halt 400, {error: "test runner not found"}.to_json unless test_runner

    test_runner.update!(machine_status: "running")

    test_run = test_runner.repository.test_runs.pending.order(created_at: :asc).first

    if test_run && test_run.repository.course_slug.eql?("redis")
      {
        test_run: {
          id: test_run.id,
          commit_sha: test_run.commit_sha,
          test_cases_json: [{slug: "jm1", tester_log_prefix: "tester::#JM1", title: "Stage #JM1 Bind to a port"}].to_json,
          logstream_url: test_run.logstream_url
        }
      }.to_json
    elsif test_run && test_run.repository.course_slug.eql?("sqlite")
      {
        test_run: {
          id: test_run.id,
          commit_sha: test_run.commit_sha,
          test_cases_json: [{slug: "dr6", tester_log_prefix: "tester::#DR6", title: "Stage #DR6 Print page size"}].to_json,
          logstream_url: test_run.logstream_url
        }
      }.to_json
    else
      halt 200, {should_retry: false}.to_json
    end
  end

  post "/services/test_runner/create_test_run_result" do
    halt 400, {error: "invalid content type"}.to_json unless request.content_type == "application/json"

    json = JSON.parse(request.body.read)

    test_run = TestRun.find_by(id: json.fetch("test_run_id"))
    test_runner = TestRunner.find_by(id: json.fetch("test_runner_id"))

    halt 404, {error: "test run not found"}.to_json if test_run.nil?
    halt 404, {error: "test runner not found"}.to_json if test_runner.nil?
    halt 400, {error: "repository mismatch"}.to_json unless test_run.repository.eql?(test_runner.repository)

    # This is a sanity check, production is actually forgiving of this case
    halt 400, {error: "test runner not running"}.to_json unless test_runner.machine_status.eql?("running")

    TestRun.transaction do
      result = test_run.results.create!(
        id: SecureRandom.uuid,
        status: json.fetch("status"),
        logs_base64: json.fetch("logs_base64")
      )

      test_run.update!(status: result.status)
    end
  end

  post "/services/test_runner/rebuild_for_test_run" do
    halt 400, {error: "invalid content type"}.to_json unless request.content_type == "application/json"

    json = JSON.parse(request.body.read)

    test_run = TestRun.find_by(id: json.fetch("test_run_id"))
    test_runner = TestRunner.find_by(id: json.fetch("test_runner_id"))

    halt 404, {error: "test run not found"}.to_json if test_run.nil?
    halt 404, {error: "test runner not found"}.to_json if test_runner.nil?
    halt 400, {error: "repository mismatch"}.to_json unless test_run.repository.eql?(test_runner.repository)

    # This is a sanity check, production is actually forgiving of this case
    halt 400, {error: "test runner not running"}.to_json unless test_runner.machine_status.eql?("running")

    test_runner.update!(machine_status: "starting") # Reprovisioning would set the start to "starting"

    build = TestRunnerBuild.create!(test_runner: test_run.repository.test_runner, status: "not_started", commit_sha: test_run.commit_sha)

    Thread.new do
      Timeout.timeout(5) { `logstream -url #{build.local_logstream_url} run echo build-success` }
      sleep 1
      build.update!(status: "success", logs_base64: Base64.strict_encode64("build-success"))
    end

    {
      id: build.id,
      commit_sha: build.commit_sha,
      logstream_url: build.logstream_url
    }.to_json
  end

  post "/services/test_runner/report_shutdown" do
    halt 400, {error: "invalid content type"}.to_json unless request.content_type == "application/json"

    json = JSON.parse(request.body.read)

    test_runner = TestRunner.find_by(id: json.fetch("test_runner_id"))
    halt 404, {error: "test runner not found"}.to_json if test_runner.nil?

    # This is a sanity check, production is actually forgiving of this case
    halt 400, {error: "test runner not running"}.to_json unless test_runner.machine_status.eql?("running")

    test_runner.update!(machine_status: "stopped")

    "success"
  end

  # --- Public Interface Ends ---

  post "/_debug/create_test_run" do
    repository_id = params.fetch("repository_id")
    test_run_id = params.fetch("test_run_id")
    TEST_RUNS[repository_id] = test_run_id

    "created test run #{test_run_id} for repository #{repository_id}"
  end
end
