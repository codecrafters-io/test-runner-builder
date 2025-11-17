TEST_RUNNER_EXECUTABLE_PATH = File.expand_path("../../dist/main.out", __dir__)
TEST_RUNNER_SOURCE_DIR = File.expand_path("../../", __dir__)
TESTERS_DIR = File.expand_path("../fixtures/testers", __dir__)

class BuildImageCommandRunner
  attr_accessor :git_repository
  attr_accessor :repository

  def initialize(git_repository:, repository:)
    self.git_repository = git_repository
    self.repository = repository
  end

  def run(build:, test_run: nil)
    tmp_dir = Dir.mktmpdir
    tester_dir = TesterDownloader.new(course: OpenStruct.new(slug: repository.course_slug), testers_root_dir: TESTERS_DIR).download_if_needed

    FileUtils.rm_rf(tmp_dir)
    FileUtils.cp_r(git_repository.tmp_dir, tmp_dir)

    test_runner_dir = Dir.mktmpdir
    `cp #{TEST_RUNNER_EXECUTABLE_PATH} #{test_runner_dir}/test-runner`

    dockerfile_handle = Tempfile.new
    dockerfile_handle.write(repository.buildpack.processed_dockerfile_contents)
    dockerfile_handle.close

    command_parts = [
      TEST_RUNNER_EXECUTABLE_PATH,
      "build_image",
      "--buildpack-slug='#{repository.buildpack.slug}'",
      "--buildpack-dockerfile-path='#{dockerfile_handle.path}'",
      "--build-id='#{build.id}'",
      "--build-logstream-url='#{build.local_logstream_url}'",
      "--codecrafters-server-url='http://localhost:6331'",
      "--course-slug='#{repository.course_slug}'",
      "--depot-token='#{ENV.fetch("DEPOT_TOKEN")}'",
      "--depot-project='#{ENV.fetch("DEPOT_PROJECT")}'",
      "--docker-image-name='test-depot-push'",
      "--docker-image-tag='test-runner-tests'",
      "--docker-registry-domain='registry.fly.io'",
      "--docker-registry-password='#{ENV.fetch("FLY_ACCESS_TOKEN")}'",
      "--docker-registry-username='x'",
      "--repository-id='dummy-repository-id'",
      "--repository-dir='#{tmp_dir}'",
      "--test-runner-dir='#{test_runner_dir}'",
      "--tester-dir='#{tester_dir}'"
    ]

    if build.commit_sha
      command_parts << "-build-commit-sha #{build.commit_sha}"
    end

    if test_run
      command_parts << "-build-test-run-logstream-url #{test_run.local_logstream_url}"
    end

    result = TTY::Command.new.run(command_parts.join(" "))
    raise "Build image script failed. Stdout: #{result.out}. Stderr: #{result.err}" unless result.status == 0

    result
  end
end
