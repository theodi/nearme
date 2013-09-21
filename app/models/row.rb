class Row
  include Mongoid::Document
  include Mongoid::Geospatial
  
  field :title,    type: String
  field :address,  type: String
  field :location, type: Point
  
  spatial_index :location
  
  has_and_belongs_to_many :councils
end