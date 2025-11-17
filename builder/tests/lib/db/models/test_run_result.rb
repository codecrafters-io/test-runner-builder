class TestRunResult < ActiveRecord::Base
  ALL_STATUSES = %w[
    success
    failure
    error
    cancelled
  ]

  enum :status, ALL_STATUSES.zip(ALL_STATUSES).to_h

  belongs_to :test_run

  def parsed_logs
    Base64.decode64(logs_base64)
  end
end
