require 'test_helper'

class ApiEndpointsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @api_endpoint = api_endpoints(:one)
    sign_in @user
  end

  test "should get index" do
    get api_endpoints_url
    assert_response :success
  end

  test "should get new" do
    get new_api_endpoint_url
    assert_response :success
  end

  test "should create api_endpoint" do
    assert_difference('ApiEndpoint.count') do
      post api_endpoints_url, params: {
        api_endpoint: {
          name: 'New API',
          url: 'https://api.example.com',
          http_method: 'get',
          headers: { 'Authorization' => 'Bearer token' },
          expected_response: { 'status' => 'ok' }
        }
      }
    end

    assert_redirected_to api_endpoint_url(ApiEndpoint.last)
    assert_equal 'API endpoint was successfully created.', flash[:notice]
  end

  test "should show api_endpoint" do
    get api_endpoint_url(@api_endpoint)
    assert_response :success
  end

  test "should get edit" do
    get edit_api_endpoint_url(@api_endpoint)
    assert_response :success
  end

  test "should update api_endpoint" do
    patch api_endpoint_url(@api_endpoint), params: {
      api_endpoint: {
        name: 'Updated API',
        url: 'https://updated-api.example.com'
      }
    }

    assert_redirected_to api_endpoint_url(@api_endpoint)
    assert_equal 'API endpoint was successfully updated.', flash[:notice]
    @api_endpoint.reload
    assert_equal 'Updated API', @api_endpoint.name
  end

  test "should destroy api_endpoint" do
    assert_difference('ApiEndpoint.count', -1) do
      delete api_endpoint_url(@api_endpoint)
    end

    assert_redirected_to api_endpoints_url
    assert_equal 'API endpoint was successfully deleted.', flash[:notice]
  end

  test "should require authentication" do
    sign_out @user
    get api_endpoints_url
    assert_redirected_to new_user_session_path
  end

  test "should check status after create" do
    stub_request(:get, 'https://api.example.com')
      .to_return(status: 200, body: '{"status":"ok"}', headers: { 'Content-Type' => 'application/json' })

    post api_endpoints_url, params: {
      api_endpoint: {
        name: 'New API',
        url: 'https://api.example.com',
        http_method: 'get'
      }
    }

    new_endpoint = ApiEndpoint.last
    assert_equal 'up', new_endpoint.status
  end

  test "should check status after update" do
    stub_request(:get, 'https://updated-api.example.com')
      .to_return(status: 200, body: '{"status":"ok"}', headers: { 'Content-Type' => 'application/json' })

    patch api_endpoint_url(@api_endpoint), params: {
      api_endpoint: {
        url: 'https://updated-api.example.com'
      }
    }

    @api_endpoint.reload
    assert_equal 'up', @api_endpoint.status
  end
end