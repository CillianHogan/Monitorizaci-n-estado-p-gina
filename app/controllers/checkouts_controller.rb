# frozen_string_literal: true

class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  def create
    price_id = ENV["STRIPE_PRO_PRICE_ID"]

    line_items = if price_id.present?
      [{ price: price_id, quantity: 1 }]
    else
      [{
        price_data: {
          currency: "eur",
          product_data: {
            name: "Plan PRO - Domain Monitor",
            description: "Monitorizacion avanzada, hasta 50 dominios y alertas por Discord/Telegram"
          },
          unit_amount: 900,
          recurring: { interval: "month" }
        },
        quantity: 1
      }]
    end

    session = Stripe::Checkout::Session.create(
      mode: "subscription",
      payment_method_types: ["card"],
      line_items: line_items,
      customer_email: current_user.email,
      client_reference_id: current_user.id.to_s,
      metadata: {
        user_id: current_user.id.to_s
      },
      success_url: success_checkout_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: cancel_checkout_url
    )

    redirect_to session.url, allow_other_host: true, status: :see_other
  rescue Stripe::StripeError => e
    redirect_to root_path, alert: "Error al iniciar el proceso de pago: #{e.message}"
  end

  def success
    if params[:session_id].present?
      begin
        session = Stripe::Checkout::Session.retrieve(params[:session_id])
        if session.client_reference_id == current_user.id.to_s || session.metadata&.user_id == current_user.id.to_s
          current_user.update(
            role: :pro,
            stripe_customer_id: session.customer,
            stripe_subscription_id: session.subscription
          )
        end
      rescue Stripe::StripeError => e
        Rails.logger.error("Error retrieving checkout session: #{e.message}")
      end
    end

    redirect_to root_path, notice: "Enhorabuena, te has suscrito con exito al Plan PRO."
  end

  def cancel
    redirect_to root_path, alert: "El proceso de suscripcion fue cancelado."
  end

  def portal
    return redirect_to root_path, alert: "No tienes una suscripcion activa." unless current_user.stripe_customer_id.present?

    portal_session = Stripe::BillingPortal::Session.create(
      customer: current_user.stripe_customer_id,
      return_url: root_url
    )

    redirect_to portal_session.url, allow_other_host: true, status: :see_other
  rescue Stripe::StripeError => e
    redirect_to root_path, alert: "Error al abrir el portal de facturacion: #{e.message}"
  end
end
