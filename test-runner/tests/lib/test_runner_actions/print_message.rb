class TestRunnerActions::PrintMessage < TestRunnerActions::Base
  attr_accessor :color
  attr_accessor :text

  validates_presence_of :color
  validates_presence_of :text, allow_blank: true

  validates_inclusion_of :color, in: %w[green red yellow blue plain]

  def args_for_test_runner
    [:color, :text]
  end

  def self.blue(message)
    new(color: "blue", text: message)
  end

  def self.green(message)
    new(color: "green", text: message)
  end

  def self.plain(message)
    new(color: "plain", text: message)
  end

  def self.red(message)
    new(color: "red", text: message)
  end

  def self.yellow(message)
    new(color: "yellow", text: message)
  end
end
