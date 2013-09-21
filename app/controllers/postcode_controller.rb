class PostcodeController < ApplicationController
  
  def index

  end
  
  def create
    postcode = Postcode.new(params[:postcode])
    if postcode.valid?
      redirect_to postcode_url(postcode.url_friendly)
    end
  end
  
  def show
    @postcode = Postcode.new(params[:id])
  end
  
  def map
  end
  
end
