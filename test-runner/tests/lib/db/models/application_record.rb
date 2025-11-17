class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  before_validation do
    self.id ||= SecureRandom.uuid
  end
end
