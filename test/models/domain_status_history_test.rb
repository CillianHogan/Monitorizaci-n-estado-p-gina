require "test_helper"

class DomainStatusHistoryTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @domain = domains(:one)
    @status_history = DomainStatusHistory.new(
      domain: @domain,
      status: :up,
      recorded_at: Time.current
    )
  end

  test "should be valid with all required attributes" do
    assert @status_history.valid?
  end

  test "should not be valid without a domain" do
    @status_history.domain = nil
    assert_not @status_history.valid?
    assert_not_nil @status_history.errors[:domain]
  end

  test "should not be valid without a status" do
    @status_history.status = nil
    assert_not @status_history.valid?
    assert_not_nil @status_history.errors[:status]
  end

  test "should not be valid without recorded_at" do
    @status_history.recorded_at = nil
    assert_not @status_history.valid?
    assert_not_nil @status_history.errors[:recorded_at]
  end

  test "should have valid status values" do
    valid_statuses = [:pending, :up, :down, :error]
    valid_statuses.each do |status|
      @status_history.status = status
      assert @status_history.valid?, "#{status} should be a valid status"
    end
  end

  test "should create history entry when domain status changes" do
    stub_request(:head, @domain.url)
      .to_return(status: 500, body: "", headers: {})

    assert_difference("DomainStatusHistory.count") do
      @domain.check_status!
    end

    history_entry = DomainStatusHistory.last
    assert_equal @domain, history_entry.domain
    assert_equal "down", history_entry.status
    assert_not_nil history_entry.recorded_at
  end
end