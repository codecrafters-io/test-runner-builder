class TestRunnerActions::AwaitTerminalBuildStatus < TestRunnerActions::Base
  attr_accessor :build_id
  attr_accessor :on_success_actions
  attr_accessor :on_failure_actions

  validates_presence_of :build_id
  validates_presence_of :on_success_actions
  validates_presence_of :on_failure_actions

  def args_for_test_runner
    [:build_id, :on_success_actions, :on_failure_actions]
  end

  def self.for_build_id(build_id, on_success_actions:, on_failure_actions:)
    new(build_id: build_id, on_success_actions: on_success_actions, on_failure_actions: on_failure_actions)
  end
end
