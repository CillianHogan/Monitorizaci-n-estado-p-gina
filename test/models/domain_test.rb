require 'test_helper'

class DomainTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @domain = domains(:one)
  end

  test "should be valid with all required attributes" do
    assert @domain.valid?
  end

  test "should not be valid without a name" do
    @domain.name = nil
    refute @domain.valid?
    assert_not_nil @domain.errors[:name]
  end

  test "should not be valid without a URL" do
    @domain.url = nil
    refute @domain.valid?
    assert_not_nil @domain.errors[:url]
  end

  test "should not be valid with invalid URL format" do
    @domain.url = 'invalid-url'
    refute @domain.valid?
    assert_not_nil @domain.errors[:url]
  end

  test "should have pending status by default" do
    new_domain = @user.domains.build(
      name: 'Test Domain',
      url: 'https://example.com'
    )
    assert_equal 'pending', new_domain.status
  end

  test "should check status successfully" do
    stub_request(:get, @domain.url)
      .to_return(status: 200, body: '', headers: {})

    @domain.check_status!
    assert_equal 'up', @domain.status
  end

  test "should mark as down when domain returns error status" do
    stub_request(:get, @domain.url)
      .to_return(status: 500, body: '', headers: {})

    @domain.check_status!
    assert_equal 'down', @domain.status
  end

  test "should mark as error and notify when connection fails" do
    stub_request(:get, @domain.url).to_raise(StandardError)

    assert_enqueued_email_with DomainMailer, :status_error_notification, args: [@domain] do
      @domain.check_status!
    end
    assert_equal 'error', @domain.status
  end

  test "should log status changes" do
    stub_request(:get, @domain.url)
      .to_return(status: 200, body: '', headers: {})

    assert_logged("Domain #{@domain.name} status changed from pending to up") do
      @domain.check_status!
    end
  end

  test "should log errors" do
    error = StandardError.new("Connection refused")
    stub_request(:get, @domain.url).to_raise(error)

    assert_logged("Error checking domain #{@domain.name}: Connection refused") do
      @domain.check_status!
    end
  end
end