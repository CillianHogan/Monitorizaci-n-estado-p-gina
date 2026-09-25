# frozen_string_literal: true

class DomainsController < ApplicationController
  before_action :set_domain, only: %i[show edit update destroy]

  def index
    @domains = current_user.domains
  end

  def show; end

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
