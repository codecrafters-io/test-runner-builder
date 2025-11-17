class Repository < ActiveRecord::Base
  belongs_to :buildpack

  has_many :test_runs
  has_many :test_runners

  validates_presence_of :course_slug
  validates_presence_of :language_slug

  after_create do
    test_runners.create!
  end

  def clone_url
    "http://host.docker.internal:6332/#{id}"
  end

  def local_clone_url
    "http://localhost:6332/#{id}"
  end

  def secret_id
    id # temp
  end

  def test_runner
    @test_runner ||= test_runners.first # Caching this so that we can mutate ID
  end
end
