class TestRunnerActions::Base
  include ActiveModel::Model

  def as_json_for_test_runner
    {
      type: self.class.name.demodulize.underscore,
      args: args_for_test_runner.map { |arg|
        value = send(arg)

        [
          arg,
          if value.is_a?(TestRunnerActions::Base)
            value.as_json_for_test_runner
          elsif value.is_a?(Array) && value.all? { |v| v.is_a?(TestRunnerActions::Base) }
            value.map { |v| v.as_json_for_test_runner }
          else
            value
          end
        ]
      }.to_h
    }
  end

  def initialize(**attributes)
    super(attributes)

    validate! # Ensure we don't construct an invalid action
  end
end
