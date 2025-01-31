require "test_helper"

class DomainsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @domain = domains(:one)
    sign_in @user

    # Stub HTTP request for domain status checking
    stub_request(:head, "https://example.com/")
      .with(
        headers: {
          "Accept"=>"*/*",
          "Accept-Encoding"=>"gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "User-Agent"=>"Ruby"
        })
      .to_return(status: 200, body: "", headers: {})
  end

  test "should get index" do
    get domains_url
    assert_response :success
  end

  test "should get new" do
    get new_domain_url
    assert_response :success
  end

  test "should create domain" do
    assert_difference("Domain.count") do
      post domains_url, params: {
        domain: {
          name: "New Domain",
          url: "https://example.com"
        }
      }
    end

    assert_redirected_to domain_url(Domain.last)
    assert_equal "Domain was successfully created.", flash[:notice]
  end

  test "should show domain" do
    get domain_url(@domain)
    assert_response :success
  end

  test "should get edit" do
    get edit_domain_url(@domain)
    assert_response :success
  end

  test "should update domain" do
    stub_request(:head, "https://updated-example.com/")
      .with(
        headers: {
          "Accept"=>"*/*",
          "Accept-Encoding"=>"gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "User-Agent"=>"Ruby"
        })
      .to_return(status: 200, body: "", headers: {})

    patch domain_url(@domain), params: {
      domain: {
        name: "Updated Domain",
        url: "https://updated-example.com"
      }
    }

    assert_redirected_to domain_url(@domain)
    assert_equal "Domain was successfully updated.", flash[:notice]
    @domain.reload
    assert_equal "Updated Domain", @domain.name
    assert_equal "up", @domain.status
  end

  test "should destroy domain" do
    assert_difference("Domain.count", -1) do
      delete domain_url(@domain)
    end

    assert_redirected_to domains_url
    assert_equal "Domain was successfully deleted.", flash[:notice]
  end

  test "should require authentication" do
    sign_out @user
    get domains_url
    assert_redirected_to new_user_session_path
  end

  test "should check status after create" do
    stub_request(:head, "https://example.com")
      .to_return(status: 200, body: "", headers: {})

    post domains_url, params: {
      domain: {
        name: "New Domain",
        url: "https://example.com"
      }
    }

    new_domain = Domain.last
    assert_equal "up", new_domain.status
  end

  test "should check status after update" do
    stub_request(:head, "https://updated-example.com")
      .to_return(status: 200, body: "", headers: {})

    patch domain_url(@domain), params: {
      domain: {
        url: "https://updated-example.com"
      }
    }

    @domain.reload
    assert_equal "up", @domain.status
  end
end
