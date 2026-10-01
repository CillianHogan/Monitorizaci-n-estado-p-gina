# frozen_string_literal: true

class DomainStatusHistory < ApplicationRecord
  belongs_to :domain

  enum :status, { pending: 0, up: 1, down: 2, error: 3 }

  validates :status, presence: true
  validates :recorded_at, presence: true

  after_create :prune_excess_records

  private

  def prune_excess_records
    excess_ids = domain.status_histories.order(recorded_at: :desc).offset(100).pluck(:id)
    domain.status_histories.where(id: excess_ids).delete_all if excess_ids.any?
  end
end
