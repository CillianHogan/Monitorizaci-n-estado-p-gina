# frozen_string_literal: true

class ApiEndpointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_api_endpoint, only: %i[show edit update destroy check_status export_csv]

  def index
    @api_endpoints = current_user.api_endpoints.order(created_at: :desc)
    @total_count = @api_endpoints.count
    @up_count = @api_endpoints.count(&:status_up?)
  end

  def show
    @histories = @api_endpoint.status_histories.order(recorded_at: :desc).limit(50)
  end

  def new
    @api_endpoint = current_user.api_endpoints.build(http_method: :get)
  end

  def create
    @api_endpoint = current_user.api_endpoints.build(api_endpoint_params)
    if @api_endpoint.save
      redirect_to @api_endpoint, notice: "Endpoint creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @api_endpoint.update(api_endpoint_params)
      redirect_to @api_endpoint, notice: "Endpoint actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @api_endpoint.destroy
    redirect_to api_endpoints_path, notice: "Endpoint eliminado."
  end

  def check_status
    @api_endpoint.check_status!
    redirect_back fallback_location: api_endpoints_path, notice: "Estado de #{@api_endpoint.name} comprobado."
  end

  def export_csv
    unless current_user.admin?
      redirect_to api_endpoint_path(@api_endpoint), alert: "La exportación de métricas en CSV es exclusiva del Plan PRO." and return
    end

    filename = "reporte-api-#{@api_endpoint.name.parameterize}-#{Time.current.strftime('%Y%m%d%H%M')}.csv"
    send_data @api_endpoint.to_csv(500), filename: filename, type: "text/csv; charset=utf-8; header=present", disposition: "attachment"
  end

  private

  def set_api_endpoint
    @api_endpoint = current_user.api_endpoints.find(params[:id])
  end

  def api_endpoint_params
    permitted = params.require(:api_endpoint).permit(
      :name, :url, :http_method, :expected_status, :timeout_seconds,
      :request_headers, :request_body, :response_keyword, :notify_on_failure,
      :notify_email, :notify_email_address, :notify_discord, :discord_webhook_url,
      :notify_telegram, :telegram_chat_id,
      notification_channel_ids: []
    )
    unless current_user.pro?
      permitted[:notify_discord] = false
      permitted[:notify_telegram] = false
      permitted[:discord_webhook_url] = nil
      permitted[:telegram_chat_id] = nil
      # Limpiar canales de tipo discord o telegram si intentaron colar sus ids
      if permitted[:notification_channel_ids].present?
        valid_ids = current_user.notification_channels.where(channel_type: "email").where(id: permitted[:notification_channel_ids]).pluck(:id)
        permitted[:notification_channel_ids] = valid_ids
      end
    end
    permitted
  end
end
