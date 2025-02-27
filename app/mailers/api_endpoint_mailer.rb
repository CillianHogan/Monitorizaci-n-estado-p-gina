# frozen_string_literal: true

class ApiEndpointMailer < ApplicationMailer
  def status_error_notification(api_endpoint)
    @api_endpoint = api_endpoint
    @user = api_endpoint.user
    mail(
      to: @user.email,
      subject: "API Endpoint Alert: #{@api_endpoint.name} is experiencing issues"
    )
  end
end
