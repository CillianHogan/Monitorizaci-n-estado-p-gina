# frozen_string_literal: true

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    event = if endpoint_secret.present?
      begin
        Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      rescue JSON::ParserError
        return head :bad_request
      rescue Stripe::SignatureVerificationError => e
        Rails.logger.error("Firma de webhook invalida: #{e.message}")
        return head :bad_request
      end
    else
      data = JSON.parse(payload, symbolize_names: true)
      Stripe::Event.construct_from(data)
    end

    case event.type
    when "checkout.session.completed"
      session = event.data.object
      user_id = session.client_reference_id || session.metadata&.user_id
      user = User.find_by(id: user_id) || User.find_by(email: session.customer_email)

      if user
        user.update!(
          role: :pro,
          stripe_customer_id: session.customer,
          stripe_subscription_id: session.subscription
        )
      end

    when "customer.subscription.deleted"
      subscription = event.data.object
      user = User.find_by(stripe_subscription_id: subscription.id) || User.find_by(stripe_customer_id: subscription.customer)

      if user
        user.update!(role: :user, stripe_subscription_id: nil)
      end
    end

    head :ok
  rescue StandardError => e
    Rails.logger.error("Error procesando webhook: #{e.message}")
    head :internal_server_error
  end
end
