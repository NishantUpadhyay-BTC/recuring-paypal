class HomeController < ApplicationController
  before_filter :authenticate_user!, only: [:index]
  def index

  end

  def pay
    redirect_to root_path
  end
end
