class Buildpack < ApplicationRecord
  validates_presence_of :course_slug
  validates_presence_of :language_slug
  validates_presence_of :slug

  def self.upsert_from_code_fixture!(code_fixture)
    buildpack = find_or_initialize_by(slug: code_fixture.fetch("buildpack_slug"))
    buildpack.course_slug = code_fixture.fetch("course_slug")
    buildpack.language_slug = code_fixture.fetch("language_slug")
    buildpack.processed_dockerfile_contents = BuildpackDockerfileProcessor.process(code_fixture.fetch("dockerfile_contents"))
    buildpack.save!

    buildpack
  end
end
