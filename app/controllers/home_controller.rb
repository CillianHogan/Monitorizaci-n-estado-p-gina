# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :pricing], raise: false

  def pricing
  end

  skip_before_action :authenticate_user!, only: [:index], raise: false

  def index; end
end
