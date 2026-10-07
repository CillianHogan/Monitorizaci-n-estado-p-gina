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
            description: "Monitorización avanzada, hasta 50 dominios y alertas por Discord/Telegram"
          },
          unit_amount: 900,
          recurring: { interval: "month" }
        },
        quantity: 1
      }]
    end

    session_params = {
      mode: "subscription",
      line_items: line_items,
      customer_email: current_user.email,
      client_reference_id: current_user.id.to_s,
      metadata: {
        user_id: current_user.id.to_s
      },
      success_url: success_checkout_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: cancel_checkout_url
    }

    # Si el usuario ya tiene un customer_id en Stripe, lo reutilizamos
    if current_user.stripe_customer_id.present?
      session_params.delete(:customer_email)
      session_params[:customer] = current_user.stripe_customer_id
    end

    session = Stripe::Checkout::Session.create(session_params)

    redirect_to session.url, allow_other_host: true, status: :see_other
  rescue Stripe::StripeError => e
    Rails.logger.error "[Stripe Checkout Error]: #{e.message}"
    redirect_to root_path, alert: "No se pudo iniciar el proceso de pago seguro. Por favor, inténtalo de nuevo en unos instantes."
  rescue StandardError => e
    Rails.logger.error "[Checkout Error]: #{e.message}"
    redirect_to root_path, alert: "Ocurrió un error inesperado al conectar con la pasarela de pago."
  end

  def success
    session_id = params[:session_id]

    if session_id.present?
      stripe_session = Stripe::Checkout::Session.retrieve(session_id)

      if stripe_session.customer.present?
        current_user.update_columns(
          stripe_customer_id: stripe_session.customer,
          stripe_subscription_id: stripe_session.subscription,
          role: :pro
        )
      else
        current_user.update_column(:role, :pro)
      end

      redirect_to domains_path, notice: "¡Enhorabuena! Tu cuenta ha sido actualizada al Plan PRO con éxito."
    else
      redirect_to domains_path, notice: "Suscripción activada con éxito."
    end
  rescue Stripe::StripeError => e
    Rails.logger.error "[Stripe Success Callback Error]: #{e.message}"
    redirect_to domains_path, alert: "El pago se procesó, pero hubo un retraso sincronizando con Stripe. Tu plan se actualizará en breve."
  end

  def cancel
    redirect_to root_path, alert: "El proceso de suscripción al Plan PRO fue cancelado. No se ha realizado ningún cobro."
  end

  def portal
    unless current_user.stripe_customer_id.present?
      redirect_to domains_path, alert: "No tienes una suscripción activa vinculada para gestionar en el portal."
      return
    end

    portal_session = Stripe::BillingPortal::Session.create(
      customer: current_user.stripe_customer_id,
      return_url: domains_url
    )

    redirect_to portal_session.url, allow_other_host: true, status: :see_other
  rescue Stripe::StripeError => e
    Rails.logger.error "[Stripe Portal Error]: #{e.message}"
    redirect_to domains_path, alert: "No se pudo abrir el portal de facturación en este momento."
  end
end
