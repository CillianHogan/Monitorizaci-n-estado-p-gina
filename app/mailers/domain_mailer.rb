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

  def status_down_notification(domain)
    @domain = domain
    @user = domain.user
    mail(
      to: @user.email,
      subject: "Domain Status Alert: #{@domain.name} is down"
    )
  end

  def status_up_notification(domain)
    @domain = domain
    @user = domain.user
    mail(
      to: @user.email,
      subject: "Domain Status Alert: #{@domain.name} is back online"
    )
  end

  def ssl_expiration_warning_notification(domain)
    @domain = domain
    @user = domain.user
    mail(
      to: @user.email,
      subject: "SSL Warning: El certificado de #{@domain.name} caduca en #{@domain.ssl_days_remaining} días"
    )
  end
  def high_latency_notification(domain, latency_ms)
    @domain = domain
    @user = domain.user
    @latency_ms = latency_ms
    mail(
      to: @user.email,
      subject: "Alerta de rendimiento: #{@domain.name} responde con lentitud (#{@latency_ms} ms)"
    )
  end

end
