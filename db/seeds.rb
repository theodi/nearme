# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
require 'httparty'
require 'csv'
require 'easting_northing'

# Add councils

councils = HTTParty.get("http://openlylocal.com/councils/all.json")

councils["councils"].each do |council|
  
  Council.find_or_create_by(snac: council["snac_id"]) do |c|
    c.name = council["name"]
    c.snac = council["snac_id"]
    c.gss = council["gss_code"]
    c.address = council["address"]
    c.url = council["url"]
    c.tel = council["telephone"]
  end
  
end

# Add schools

CSV.foreach("#{Rails.root}/lib/data/extract.csv", :headers => :first_row) do |r|
   gss = r["GSSLACode (name)"]
   begin
     ll = EastingNorthing.eastingNorthingToLatLong(r["Easting"].to_i, r["Northing"].to_i)
     council = Council.find_by(gss: gss)
     dataset = council.datasets.find_or_create_by(name: "Schools")
     address = [r["Street"], r["Postcode"], r["Locality"], r["Town"], r["Address3"], r["Postcode"]].reject { |c| c.blank? }.join(", ")
     dataset.rows.create(
      title: r["EstablishmentName"],
      address: address,
      location: [ll["lat"], ll["long"]]
     )
     dataset.save
   rescue Mongoid::Errors::DocumentNotFound
     nil
   end
end

CSV.foreach("#{Rails.root}/lib/data/parks.csv") do |r|
  council = Council.find_by(snac: "41UD")
  dataset = council.datasets.find_or_create_by(name: "Parks")
  dataset.rows.create(
   title: r[0],
   address: r[1],
   location: [r[3], r[2]]
  )
  dataset.save
end

# council = Council.find_by(gss: "E10000028")
# data = MySociety::MapIt::Postcode.new("ws149sq")
# council.rows.where('location' => {'$near' => [data.to_point.x, data.to_point.y]}, :type => 'schools')
