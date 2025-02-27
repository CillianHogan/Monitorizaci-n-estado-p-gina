# frozen_string_literal: true

class DomainMailer < ApplicationMailer
  def status_error_notification(domain)
    @domain = domain
    @user = domain.user
    mail(
      to: @user.email,
      subject: "Domain Status Alert: #{@domain.name} is experiencing issues"
    )
  end
end
