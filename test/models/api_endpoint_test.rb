# frozen_string_literal: true

require 'test_helper'

class ApiEndpointTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @api_endpoint = api_endpoints(:one)
  end

  test 'should be valid with all required attributes' do
    assert @api_endpoint.valid?
  end

  test 'should not be valid without a name' do
    @api_endpoint.name = nil
    assert_not @api_endpoint.valid?
    assert_not_nil @api_endpoint.errors[:name]
  end

  test 'should not be valid without a URL' do
    @api_endpoint.url = nil
    assert_not @api_endpoint.valid?
    assert_not_nil @api_endpoint.errors[:url]
  end

  test 'should not be valid with invalid URL format' do
    @api_endpoint.url = 'invalid-url'
    assert_not @api_endpoint.valid?
    assert_not_nil @api_endpoint.errors[:url]
  end

  test 'should have pending status by default' do
    new_endpoint = @user.api_endpoints.build(
      name: 'Test API',
      url: 'https://api.example.com'
    )
    assert_equal 'pending', new_endpoint.status
  end

  test 'should check status successfully' do
    stub_request(:get, @api_endpoint.url)
      .to_return(status: 200, body: '{"status":"ok"}', headers: { 'Content-Type' => 'application/json' })

    @api_endpoint.check_status!
    assert_equal 'up', @api_endpoint.status
  end

  test 'should mark as down when API returns error status' do
    stub_request(:get, @api_endpoint.url)
      .to_return(status: 500, body: '', headers: {})

    @api_endpoint.check_status!
    assert_equal 'down', @api_endpoint.status
  end

  test 'should mark as error and notify when connection fails' do
    stub_request(:get, @api_endpoint.url).to_raise(StandardError)

    @api_endpoint.check_status!
    assert_emails 1
    assert_equal 'error', @api_endpoint.status
  end

  test 'should validate expected response when present' do
    @api_endpoint.expected_response = { 'status' => 'ok' }
    stub_request(:get, @api_endpoint.url)
      .to_return(status: 200, body: '{"status":"ok"}', headers: { 'Content-Type' => 'application/json' })

    @api_endpoint.check_status!
    assert_equal 'up', @api_endpoint.status
  end

  test "should mark as down when response doesn't match expected" do
    @api_endpoint.expected_response = { 'status' => 'ok' }
    stub_request(:get, @api_endpoint.url)
      .to_return(status: 200, body: '{"status":"error"}', headers: { 'Content-Type' => 'application/json' })

    @api_endpoint.check_status!
    assert_equal 'down', @api_endpoint.status
  end
end
