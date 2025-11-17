class TestRunner < ApplicationRecord
  ALL_MACHINE_STATUSES = [
    "stopped",
    "starting",
    "running"
  ]

  enum machine_status: ALL_MACHINE_STATUSES.zip(ALL_MACHINE_STATUSES).to_h

  belongs_to :repository

  before_validation do
    self.machine_status ||= "starting"
  end
end
