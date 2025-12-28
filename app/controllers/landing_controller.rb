# frozen_string_literal: true

class LandingController < ApplicationController
  layout 'landing'

  def show
    @lead = Lead.new
  end

  def price
    @plans = PricingConfig.plans
  end

  def lp1
    @lead = Lead.new
  end

  def lp2
    @lead = Lead.new
    @plans = PricingConfig.plans
  end

  def lp_magic_1
    @lead = Lead.new
    @plans = PricingConfig.plans
  end

  def lp_magic_2
    @lead = Lead.new
  end

  def lp_magic_3
    @lead = Lead.new
    @plans = PricingConfig.plans
  end

  def index
    @landings = [
      { path: root_path, name: 'Главная', description: 'Основной лендинг' },
      { path: lp1_path, name: 'LP1', description: 'Вариант 1' },
      { path: lp2_path, name: 'LP2', description: 'Вариант 2 с тарифами' },
      { path: lp_magic_1_path, name: 'LP Magic 1', description: 'ROI-фокус с калькулятором' },
      { path: lp_magic_2_path, name: 'LP Magic 2', description: 'Минималистичный дизайн' },
      { path: lp_magic_3_path, name: 'LP Magic 3', description: 'Сторителлинг с countdown' }
    ]
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
