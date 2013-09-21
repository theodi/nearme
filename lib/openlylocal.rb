require 'httparty'

class OpenlyLocal
  include HTTParty
  base_uri 'openlylocal.com'
  
  def initialize(postcode)
    @response = self.class.get("/areas/postcodes/#{postcode}.json")
  end
  
  def ward
    @response['postcode']['ward']
  end
  
  def council
    @response['postcode']['ward']['council']
  end
  
  def members
    @response['postcode']['ward']['members']
  end
  
end