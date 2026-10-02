# frozen_string_literal: true

class ApiEndpointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_api_endpoint, only: %i[show edit update destroy check_status export_csv]

  def index
    @api_endpoints = current_user.api_endpoints.order(created_at: :desc)
    @total_count = @api_endpoints.count
    @up_count = @api_endpoints.count(&:status_up?)
    @down_count = @api_endpoints.count { |e| e.status_down? || e.status_error? }
  end

  def show; end

  def new
    @api_endpoint = current_user.api_endpoints.build
  end

  def edit; end

  def create
    @api_endpoint = current_user.api_endpoints.build(api_endpoint_params)

    if @api_endpoint.save
      redirect_to @api_endpoint, notice: "Endpoint API creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @api_endpoint.update(api_endpoint_params)
      redirect_to @api_endpoint, notice: "Endpoint API actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @api_endpoint.destroy
    redirect_to api_endpoints_path, notice: "Endpoint API eliminado exitosamente."
  end

  def check_status
    @api_endpoint.check_status!
    redirect_back fallback_location: api_endpoints_path, notice: "Estado de #{@api_endpoint.name} comprobado."
  end


  def export_csv
    filename = "reporte-api-#{@api_endpoint.name.parameterize}-#{Time.current.strftime('%Y%m%d%H%M')}.csv"
    send_data @api_endpoint.to_csv(500), filename: filename, type: "text/csv; charset=utf-8; header=present", disposition: "attachment"
  end

  private

  def set_api_endpoint
    @api_endpoint = current_user.api_endpoints.find(params[:id])
  end

  def api_endpoint_params
    params.require(:api_endpoint).permit(
      :name, :url, :http_method, :headers, :expected_response,
      :notify_email, :notify_email_address,
      :notify_discord, :discord_webhook_url,
      :notify_telegram, :telegram_chat_id, :telegram_bot_token
    )
  end
end
