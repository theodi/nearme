require 'openlylocal'

class Postcode
  
  def initialize(postcode)
    @postcode = UKPostcode.new(postcode)
    @data = Rails.cache.fetch(postcode, :expires_in => 12.hours) do
      MySociety::MapIt::Postcode.new(postcode)
    end
  end
  
  def valid?
    @postcode.valid? && @postcode.full?
  end
  
  def norm
    @postcode.norm
  end
  
  def council
    if @data.two_tier?
      Council.find_by(:snac => @data.local_authority[:district].snac)
    else
      Council.find_by(:snac => @data.local_authority.snac)
    end
  end
  
  def county
    if @data.two_tier?
      Council.find_by(:snac => @data.local_authority[:county].snac)
    end
  end
  
  def ward
    @data.ward
  end
  
  def councillors
    c = []
    ol.members.each do |m|
      c << {
        :name    => [m['first_name'], m['last_name']].join(' '),
        :email   => m['email'],
        :address => m['address'],
        :tel     => m['telephone'],
        :party   => m['party']
      }
    end
    c
  end
  
  def datasets
    if @data.two_tier?
      datasets = county.datasets.concat council.datasets
    else
      council = self.council
      datasets = self.council.datasets
    end
    results = {}
    datasets.each do |dataset|
      results[dataset.name] = dataset.rows.where('location' => {'$near' => [@data.to_point.x, @data.to_point.y]}).limit(5)
    end
    results
  end
  
  def constituency
    Rails.cache.fetch("TWFY-#{url_friendly}", :expires_in => 12.hours) do
      response = HTTParty.get("http://www.theyworkforyou.com/api/getMP?postcode=#{url_friendly}&output=js&key=#{ENV['TWFY_KEY']}")
      {
        :name => response['constituency'],
        :mp   => {
            :name  => response['full_name'],
            :party => response['party'],
            :photo => "http://www.theyworkforyou.com" + response['image'],
            :url   => "http://www.theyworkforyou.com" + response['url']
        }
      }
    end
  end
    
  def ol
    OpenlyLocal.new(url_friendly)
  end
  
  def url_friendly
    @postcode.norm.delete(' ')
  end
  
  def lat_lng 
    {
      :lat => @data.to_point.x,
      :lng => @data.to_point.y
    }
  end
  
end