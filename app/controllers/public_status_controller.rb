class PublicStatusController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def index
    @domains = Domain.all
    @api_endpoints = ApiEndpoint.all if defined?(ApiEndpoint)
  end

  def show
    token = params[:token]
    @domain = Domain.find_by(public_token: token)
    @api_endpoint = ApiEndpoint.find_by(public_token: token) if defined?(ApiEndpoint) && !@domain
    
    if @domain.nil? && @api_endpoint.nil?
      redirect_to root_path, alert: "Service not found"
    end
  end
end