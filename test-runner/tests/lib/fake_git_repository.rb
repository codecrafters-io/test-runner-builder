class FakeGitRepository
  attr_accessor :tmp_dir
  attr_accessor :repository

  def initialize(copy_from_dir, repository)
    @tmp_dir = Dir.mktmpdir
    @repository = repository

    FileUtils.rm_rf(tmp_dir)
    FileUtils.cp_r(copy_from_dir, tmp_dir)

    commands = [
      "git -C #{tmp_dir} init ",
      "git -C #{tmp_dir} checkout -b master",
      "git -C #{tmp_dir} add  .",
      "git -C #{tmp_dir} commit -m \"testing [skip ci]\"",
      "git -C #{tmp_dir} remote add origin #{repository.local_clone_url}"
    ]

    commands.each do |command|
      output = `#{command} 2>&1`
      raise "Git command failed: #{command}. Output: #{output}" unless $?.success?
    end
  end

  def commit_changes_to_branch!(branch: "testing", &block)
    block.call(tmp_dir)

    commands = [
      "git -C #{tmp_dir} checkout -b #{branch} || git -C #{tmp_dir} checkout #{branch}",
      "git -C #{tmp_dir} add  .",
      "git -C #{tmp_dir} commit -m \"changes [skip ci]\""
    ]

    commands.each do |command|
      output = `#{command} 2>&1`
      raise "Git command failed: #{command}. Output: #{output}" unless $?.success?
    end

    commit_sha = head_commit_sha

    push_to_git_daemon!(branch: branch)

    commands = [
      "git -C #{tmp_dir} checkout -f master"
    ]

    commands.each do |command|
      output = `#{command} 2>&1`
      raise "Git command failed: #{command}. Output: #{output}" unless $?.success?
    end

    commit_sha
  end

  def head_commit_sha
    `git -C #{tmp_dir} rev-parse HEAD`.strip
  end

  def push_to_git_daemon!(branch: "master")
    GitApiGateway.new.create_repository(repository.id)

    result = TTY::Command.new.run("git -C #{tmp_dir} push -f -u origin #{branch}")
    raise "Git command failed: #{command}. Stdout: #{result.out}, Stderr: #{result.err}" unless result.status == 0

    result
  end

  def push_changes_to_master!(&block)
    block.call(tmp_dir)

    commands = [
      "git -C #{tmp_dir} add  .",
      "git -C #{tmp_dir} commit --allow-empty -m \"changes\""
    ]

    commands.each do |command|
      output = `#{command} 2>&1`
      raise "Git command failed: #{command}. Output: #{output}" unless $?.success?
    end

    push_to_git_daemon!(branch: "master")
  end

  def set_remote_url(remote_url)
    command = "git -C #{tmp_dir} remote set-url origin #{remote_url}"
    result = TTY::Command.new.run(command)
    raise "Git command failed: #{command}. Stdout: #{result.out}, Stderr: #{result.err}" unless result.status == 0
  end
end
