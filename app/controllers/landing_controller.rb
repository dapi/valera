# frozen_string_literal: true

class LandingController < ApplicationController
  layout 'landing'

  def show
    @lead = Lead.new
  end

  def price
    @plans = PricingConfig.plans
  end

  def create_lead
    @lead = Lead.new(lead_params)
    @lead.source = 'landing_page'

    if @lead.save
      redirect_to root_path, notice: 'Спасибо! Мы свяжемся с вами в ближайшее время.'
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def lead_params
    params.require(:lead).permit(:name, :phone, :company_name, :city, :utm_source, :utm_medium, :utm_campaign)
  end
end
