class TestRun < ApplicationRecord
  ALL_STATUSES = %w[
    pending
    success
    failure
    error
    cancelled
  ]

  enum status: ALL_STATUSES.zip(ALL_STATUSES).to_h

  belongs_to :repository
  belongs_to :submission, optional: true

  has_many :results, class_name: "TestRunResult"

  before_validation do
    self.status ||= "pending"
  end

  def logstream_url
    "redis://host.docker.internal:6334/test-run-#{id}"
  end

  def local_logstream_url
    "redis://localhost:6334/test-run-#{id}"
  end
end
