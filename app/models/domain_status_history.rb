class DomainStatusHistory < ApplicationRecord
  belongs_to :domain

  enum :status, { pending: 0, up: 1, down: 2, error: 3 }

  validates :status, presence: true
  validates :recorded_at, presence: true
end
