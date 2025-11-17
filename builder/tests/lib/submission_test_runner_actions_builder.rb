# This is a simplified version of the SubmissionTestRunnerActionsBuilder in core
class SubmissionTestRunnerActionsBuilder
  def self.build(submission:, test_run:, pending_build:)
    actions = []

    if pending_build.present?
      actions << TestRunnerActions::PrintMessage.green("Welcome back! Note that this might take a while...")
    end

    actions << TestRunnerActions::PrintMessage.plain("")

    # If there's a panding build present, stream build logs first
    if pending_build
      actions << TestRunnerActions::PrintMessage.plain("Streaming build logs...")
      actions << TestRunnerActions::PrintMessage.plain("")
      actions << TestRunnerActions::StreamLogs.from_url(pending_build.local_logstream_url)

      on_success_actions = [
        TestRunnerActions::Sleep.milliseconds(1000)
      ]

      on_failure_actions = [
        TestRunnerActions::PrintMessage.red(""),
        TestRunnerActions::PrintMessage.red("Looks like your codebase failed to build."),
        TestRunnerActions::PrintMessage.red("If you think this is a CodeCrafters error, please let us know at hello@codecrafters.io."),
        TestRunnerActions::PrintMessage.red(""),
        TestRunnerActions::Terminate.with_exit_code(0)
      ]

      actions << TestRunnerActions::AwaitTerminalBuildStatus.for_build_id(
        pending_build.id,
        on_success_actions: on_success_actions,
        on_failure_actions: on_failure_actions
      )
    end

    actions << TestRunnerActions::PrintMessage.plain("")
    actions << TestRunnerActions::PrintMessage.plain("Running tests on your code. Logs should appear shortly...")
    actions << TestRunnerActions::PrintMessage.plain("")

    # Small delay, perceive logs as streamed
    actions << TestRunnerActions::Sleep.milliseconds(200)
    actions << TestRunnerActions::StreamLogs.from_url(test_run.local_logstream_url)
    actions << TestRunnerActions::PrintMessage.plain("")

    actions << TestRunnerActions::AwaitTerminalSubmissionStatus.for_submission_id(
      submission.id,
      on_success_actions: [
        TestRunnerActions::PrintMessage.plain(""),
        TestRunnerActions::PrintMessage.plain("Test passed. Congrats!"),
        TestRunnerActions::PrintMessage.plain("")
      ],
      on_failure_actions: [
        TestRunnerActions::PrintMessage.plain(""),
        TestRunnerActions::PrintMessage.plain("Tests failed! Oops."),
        TestRunnerActions::PrintMessage.plain("")
      ]
    )

    actions
  end
end
