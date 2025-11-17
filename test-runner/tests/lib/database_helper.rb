module DatabaseHelper
  def self.clean
    TestRunResult.delete_all
    TestRun.delete_all
    TestRunnerBuild.delete_all
    Submission.delete_all
    Repository.delete_all
    # TestRunnerInfrastructure
  end
end
