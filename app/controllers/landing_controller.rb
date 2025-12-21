# frozen_string_literal: true

class LandingController < ApplicationController
  layout 'landing'

  def show
    @lead = Lead.new
  end

  def create_lead
    @lead = Lead.new(lead_params)
    @lead.source = 'landing_page'
    @lead.utm_source = params[:utm_source]
    @lead.utm_medium = params[:utm_medium]
    @lead.utm_campaign = params[:utm_campaign]

    if @lead.save
      redirect_to root_path, notice: 'Спасибо! Мы свяжемся с вами в ближайшее время.'
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def lead_params
    params.require(:lead).permit(:name, :phone, :company_name, :city)
  end
end
