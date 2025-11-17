TEST_RUNNER_LINUX_EXECUTABLE_PATH = File.expand_path("../../dist/main-linux.out", __dir__)
TESTERS_DIR = File.expand_path("../fixtures/testers", __dir__)

class RunTestsCommandRunner
  attr_accessor :git_repository
  attr_accessor :repository

  def initialize(git_repository:, repository:)
    self.git_repository = git_repository
    self.repository = repository
  end

  def dockerfile_path
    repository.dockerfile_path(git_repository)
  end

  def run
    tmp_dir = Dir.mktmpdir
    tester_dir = TesterDownloader.new(course: OpenStruct.new(slug: repository.course_slug), testers_root_dir: TESTERS_DIR).download_if_needed

    FileUtils.rm_rf(tmp_dir)
    FileUtils.cp_r(git_repository.tmp_dir, tmp_dir)

    dockerfile_handle = Tempfile.new
    dockerfile_handle.write(repository.buildpack.processed_dockerfile_contents)
    dockerfile_handle.close

    puts File.read(dockerfile_handle.path)

    # Required for build
    FileUtils.mkdir_p("#{tmp_dir}/test-runner")
    FileUtils.cp(TEST_RUNNER_LINUX_EXECUTABLE_PATH, "#{tmp_dir}/test-runner/test-runner")
    FileUtils.cp_r(tester_dir, "#{tmp_dir}/tester")

    result = TTY::Command.new.run("docker build --quiet -t test_runner_test_image -f #{dockerfile_handle.path} #{tmp_dir}")
    raise "Docker build failed. Stdout: #{result.out}. Stderr: #{result.err}" unless result.status == 0

    command_parts = [
      "docker run",
      "-e CODECRAFTERS_SERVER_URL=http://host.docker.internal:6331",
      "-e CODECRAFTERS_TEST_RUNNER_ID=#{repository.test_runner.id}",
      "-e REPOSITORY_ID=#{repository.id}",
      "--add-host=host.docker.internal:host-gateway", # Required for CI, works by default on macOS
      "--rm ",
      "test_runner_test_image"
    ]

    result = TTY::Command.new.run(command_parts.join(" "))
    raise "Test runner script failed. Stdout: #{result.out}. Stderr: #{result.err}" unless result.status == 0

    result
  end
end
