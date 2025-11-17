class TestRunnerActions::Sleep < TestRunnerActions::Base
  attr_accessor :duration_in_milliseconds

  validates_presence_of :duration_in_milliseconds
  validates_numericality_of :duration_in_milliseconds, greater_than: 0

  def args_for_test_runner
    [:duration_in_milliseconds]
  end

  def self.milliseconds(duration_in_milliseconds)
    new(duration_in_milliseconds: duration_in_milliseconds)
  end

  def self.seconds(duration_in_seconds)
    new(duration_in_milliseconds: duration_in_seconds * 1000)
  end
end
