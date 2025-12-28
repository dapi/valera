# frozen_string_literal: true

module Admin
  class ModelsController < Admin::ApplicationController
    before_action :authorize_superuser!

    # Disable create, edit, update, destroy actions (read-only resource)
    def new
      flash[:error] = 'Models are managed automatically by ruby_llm'
      redirect_to admin_models_path
    end

    def create
      flash[:error] = 'Models are managed automatically by ruby_llm'
      redirect_to admin_models_path
    end

    def edit
      flash[:error] = 'Models are managed automatically by ruby_llm'
      redirect_to admin_model_path(params[:id])
    end

    def update
      flash[:error] = 'Models are managed automatically by ruby_llm'
      redirect_to admin_model_path(params[:id])
    end

    def destroy
      flash[:error] = 'Models cannot be deleted manually'
      redirect_to admin_models_path
    end
  end
end
