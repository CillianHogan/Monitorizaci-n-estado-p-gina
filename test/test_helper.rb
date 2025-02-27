# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'webmock/minitest'

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper
    include ActionMailer::TestHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def assert_logged(expected_message)
      log_messages = []
      logger = ActiveSupport::Logger.new(StringIO.new).tap do |l|
        l.formatter = ->(_, _, _, msg) { log_messages << msg }
      end

      begin
        original_logger = Rails.logger
        Rails.logger = logger
        yield if block_given?
        assert_includes log_messages, expected_message, "Expected log message '#{expected_message}' was not found"
      ensure
        Rails.logger = original_logger
      end
    end

    def assert_valid_api_endpoint_status(endpoint, status)
      assert_includes ApiEndpoint.statuses.keys, status.to_s, "Invalid status: #{status}"
      assert_equal status.to_s, endpoint.status
    end

    def assert_valid_http_method(endpoint, method)
      assert_includes ApiEndpoint.http_methods.keys, method.to_s, "Invalid HTTP method: #{method}"
      assert_equal method.to_s, endpoint.http_method
    end
  end
end
