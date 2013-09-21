class Dataset
  include Mongoid::Document
  
  field :name,    type: String
  field :url,     type: String
  field :headers, type: Boolean, default: false
  
  has_and_belongs_to_many :rows
  has_and_belongs_to_many :councils
end