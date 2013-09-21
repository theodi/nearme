require 'csv'
require 'pry-remote'

class DatasetController < ApplicationController

  def index
    
  end
  
  def new
  end
  
  def create
    if params[:url]
      @errors = {}
      if params[:url].blank?
        @errors[:url] = "You must specify a URL"
      else
        csv = HTTParty.get(params[:url])
        @data = CSV.parse csv.body rescue nil
        if params[:headers]
          @data.shift
          headers = true
        end
        @errors[:url] = "Sorry, only CSV format is supported at the moment" if @data.nil?
      end
      
      if params[:council].blank?
        @errors[:council] = "You must select a council"
      end
      
      if @errors.blank?
        council = Council.find_by(snac: params[:council])
        @dataset = council.datasets.create(
          name: params[:type].pluralize.titleize,
          url: params[:url],
          headers: headers
        )
        render 'dataset/check'
      else
        render 'dataset/new'
      end
    end
  end
  
  def update
    if params[:id]
      dataset = Dataset.find(params[:id])
      csv = HTTParty.get(dataset.url)
      data = CSV.parse csv.body rescue nil
      if dataset.headers
        data.shift
      end
      
      col = {}
      
      params[:cols].each do |k,v|
        col[v] = k.to_i
      end
      
      data.each do |row|
        if col["Easting"] && col["Northing"]
          ll = EastingNorthing.eastingNorthingToLatLong(row[col["Easting"]].to_i, row[col["Northing"]].to_i)
          latlng = [ll["lat"], ll["long"]]
        elsif col["Easting, Northing"]
          en = row[col["Easting, Northing"]].split(",")
          ll = EastingNorthing.eastingNorthingToLatLong(en[0].to_i, en[1].to_i)
          latlng = [ll["lat"], ll["long"]]
        elsif col["Northing, Easting"]
          en = row[col["Northing, Easting"]].split(",")
          ll = EastingNorthing.eastingNorthingToLatLong(en[1].to_i, en[0].to_i)
          latlng = [ll["lat"], ll["long"]]
        elsif col["Latitude, Longitude"]
          ll = row[col["Latitude, Longitude"]].split(",")
          latlng = ll[0], ll[1]
        elsif col["Longitude, Latitude"]
          ll = row[col["Longitude, Latitude"]].split(",")
          latlng = ll[1], ll[0]
        else
          latlng = [row[col["Latitude"]], row[col["Longitude"]]]
        end
                
        address1 = row[col["Address1"]] rescue nil
        address2 = row[col["Address2"]] rescue nil
        address3 = row[col["Address3"]] rescue nil
        address4 = row[col["Address4"]] rescue nil
        
        address = [address1, address2, address3, address4].reject { |c| c.blank? }.join(", ")
        
        dataset.rows.create(
         title: row[col["Name"]],
         address: address,
         location: latlng
        )
        dataset.save
      end
      
    end
  end
  

end