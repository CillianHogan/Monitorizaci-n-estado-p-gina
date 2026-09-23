# frozen_string_literal: true

class SslCheckerJob < ApplicationJob
  queue_as :default

  def perform
    Domain.find_each do |domain|
      domain.check_ssl_expiration_alert!
    end
  end
end
