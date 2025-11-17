class TestRunnerActions::StreamLogs < TestRunnerActions::Base
  attr_accessor :logstream_url

  validates_presence_of :logstream_url

  def args_for_test_runner
    [:logstream_url]
  end

  def self.from_url(logstream_url)
    new(logstream_url: logstream_url)
  end
end
