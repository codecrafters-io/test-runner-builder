class TestRunnerBuild < ApplicationRecord
  ALL_STATUSES = %w[
    not_started
    in_progress
    success
    failure
    error
  ]

  enum status: ALL_STATUSES.zip(ALL_STATUSES).to_h

  belongs_to :test_runner

  validates_presence_of :commit_sha
  validates_presence_of :status

  before_validation do
    self.status ||= "not_started"
  end

  def logstream_url
    "redis://host.docker.internal:6334/test-runner-build-#{id}"
  end

  def local_logstream_url
    "redis://localhost:6334/test-runner-build-#{id}"
  end

  def parsed_logs
    Base64.strict_decode64(logs_base64)
  end
end
