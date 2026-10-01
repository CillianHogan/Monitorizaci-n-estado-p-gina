# frozen_string_literal: true

class ApiEndpointStatusHistory < ApplicationRecord
  belongs_to :api_endpoint

  enum :status, { up: 0, down: 1, error: 2 }, default: :up, prefix: true

  validates :status, presence: true
  validates :recorded_at, presence: true
end
