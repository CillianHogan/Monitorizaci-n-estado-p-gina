class ApiEndpointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_api_endpoint, only: [ :show, :edit, :update, :destroy ]

  def index
    @api_endpoints = current_user.api_endpoints
  end

  def show
  end

  def new
    @api_endpoint = current_user.api_endpoints.build
  end

  def create
    @api_endpoint = current_user.api_endpoints.build(api_endpoint_params)

    if @api_endpoint.save
      @api_endpoint.check_status!
      redirect_to @api_endpoint, notice: "API endpoint was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @api_endpoint.update(api_endpoint_params)
      @api_endpoint.check_status!
      redirect_to @api_endpoint, notice: "API endpoint was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @api_endpoint.destroy
    redirect_to api_endpoints_url, notice: "API endpoint was successfully deleted."
  end


  private

  def set_api_endpoint
    @api_endpoint = current_user.api_endpoints.find(params[:id])
  end

  def api_endpoint_params
    params.require(:api_endpoint).permit(:name, :url, :http_method, headers: {}, expected_response: {})
  end
end