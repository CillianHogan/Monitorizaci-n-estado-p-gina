# frozen_string_literal: true

class ApiEndpointStatusHistory < ApplicationRecord
  belongs_to :api_endpoint

  enum :status, { up: 0, down: 1, error: 2 }, default: :up, prefix: true

  validates :status, presence: true
  validates :recorded_at, presence: true

  after_create :prune_excess_records

  private

  def prune_excess_records
    excess_ids = api_endpoint.status_histories.order(recorded_at: :desc).offset(100).pluck(:id)
    api_endpoint.status_histories.where(id: excess_ids).delete_all if excess_ids.any?
  end
end
