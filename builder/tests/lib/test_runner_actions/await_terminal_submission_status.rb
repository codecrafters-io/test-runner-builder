class TestRunnerActions::AwaitTerminalSubmissionStatus < TestRunnerActions::Base
  attr_accessor :submission_id
  attr_accessor :on_success_actions
  attr_accessor :on_failure_actions

  validates_presence_of :submission_id
  validates_presence_of :on_success_actions
  validates_presence_of :on_failure_actions

  def args_for_test_runner
    [:submission_id, :on_success_actions, :on_failure_actions]
  end

  def self.for_submission_id(submission_id, on_success_actions:, on_failure_actions:)
    new(submission_id: submission_id, on_success_actions: on_success_actions, on_failure_actions: on_failure_actions)
  end
end
