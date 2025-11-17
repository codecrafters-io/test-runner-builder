class TestRunnerActions::Terminate < TestRunnerActions::Base
  attr_accessor :exit_code

  validates_presence_of :exit_code

  def args_for_test_runner
    [:exit_code]
  end

  def self.with_exit_code(exit_code)
    new(exit_code: exit_code)
  end
end
