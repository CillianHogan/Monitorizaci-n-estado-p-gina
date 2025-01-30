class DomainsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_domain, only: [:show, :edit, :update, :destroy]

  def index
    @domains = current_user.domains
  end

  def show
  end

  def new
    @domain = current_user.domains.build
  end

  def create
    @domain = current_user.domains.build(domain_params)

    if @domain.save
      @domain.check_status!
      redirect_to @domain, notice: 'Domain was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @domain.update(domain_params)
      @domain.check_status!
      redirect_to @domain, notice: 'Domain was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @domain.destroy
    redirect_to domains_url, notice: 'Domain was successfully deleted.'
  end

  private

  def set_domain
    @domain = current_user.domains.find(params[:id])
  end

  def domain_params
    params.require(:domain).permit(:name, :url)
  end
end