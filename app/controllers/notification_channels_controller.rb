# frozen_string_literal: true

class NotificationChannelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_channel, only: [:set_default, :destroy]

  def index
    @channels = current_user.notification_channels.order(created_at: :desc)
    @new_channel = current_user.notification_channels.build
  end

  def create
    @channel = current_user.notification_channels.build(channel_params)
    if @channel.save
      redirect_to notification_channels_path, notice: "Canal agregado con éxito."
    else
      @channels = current_user.notification_channels.order(created_at: :desc)
      @new_channel = @channel
      render :index, status: :unprocessable_entity
    end
  end

  def set_default
    @channel.update(is_default: true)
    redirect_to notification_channels_path, notice: "Canal marcado como predeterminado."
  end

  def destroy
    @channel.destroy
    redirect_to notification_channels_path, notice: "Canal eliminado."
  end

  private

  def set_channel
    @channel = current_user.notification_channels.find(params[:id])
  end

  def channel_params
    params.require(:notification_channel).permit(:name, :channel_type, :destination, :is_default)
  end
end
