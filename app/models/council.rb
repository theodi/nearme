class Council
  include Mongoid::Document
  
  field :name,    type: String
  field :snac,    type: String
  field :gss,     type: String
  field :address, type: String
  field :url,     type: String
  field :tel,     type: String
  
  has_and_belongs_to_many :datasets 
end
