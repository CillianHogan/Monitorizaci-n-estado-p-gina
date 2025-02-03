require "test_helper"

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
    assert_not @domain.valid?
    assert_not_nil @domain.errors[:name]
  end

  test "should not be valid without a URL" do
    @domain.url = nil
    assert_not @domain.valid?
    assert_not_nil @domain.errors[:url]
  end

  test "should not be valid with invalid URL format" do
    @domain.url = "invalid-url"
    assert_not @domain.valid?
    assert_not_nil @domain.errors[:url]
  end

  test "should have pending status by default" do
    new_domain = @user.domains.build(
      name: "Test Domain",
      url: "https://example.com"
    )
    assert_equal "pending", new_domain.status
  end

  test "should check status successfully" do
    stub_request(:head, @domain.url)
      .to_return(status: 200, body: "", headers: {})

    @domain.check_status!
    assert_equal "up", @domain.status
  end

  test "should mark as down when domain returns error status" do
    stub_request(:head, @domain.url)
      .to_return(status: 500, body: "", headers: {})

    @domain.check_status!
    assert_equal "down", @domain.status
  end

  test "should mark as error and notify when connection fails" do
    stub_request(:head, @domain.url).to_raise(StandardError)

    @domain.check_status!
    assert_emails 1
    assert_equal "error", @domain.status
  end
end
