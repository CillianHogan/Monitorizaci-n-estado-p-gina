# frozen_string_literal: true

class DomainsController < ApplicationController
  before_action :set_domain, only: %i[show edit update destroy]

  def index
    @domains = current_user.domains
  end

  def show
    # Traemos un maximo de 500 puntos recientes con solo los campos necesarios para la grafica
    @chart_data = @domain.status_histories
                         .select(:id, :recorded_at, :response_time_ms, :http_code, :status)
                         .where("recorded_at >= ?", 7.days.ago)
                         .order(recorded_at: :asc)
    # Si tiene menos de 50 registros en 7 dias, aseguramos los ultimos 100 disponibles
    if @chart_data.size < 50
      @chart_data = @domain.status_histories
                           .select(:id, :recorded_at, :response_time_ms, :http_code, :status)
                           .order(recorded_at: :desc)
                           .limit(100)
                           .reverse
    end
  end

  def new
    @domain = current_user.domains.build
  end

  def edit; end

  def create
    @domain = current_user.domains.build(domain_params)

    if @domain.save
      CheckDomainStatusJob.perform_later(@domain)
      redirect_to @domain, notice: 'Domain was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @domain.update(domain_params)
      CheckDomainStatusJob.perform_later(@domain)
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
    params.expect(domain: %i[name url])
  end
end
