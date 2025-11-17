class Submission < ApplicationRecord
  belongs_to :repository
  has_many :test_runs

  validates_presence_of :commit_sha

  def logstream_url
    test_runs.first.logstream_url
  end
end
