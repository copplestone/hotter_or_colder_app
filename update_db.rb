require 'sinatra'
require 'net/http'
require 'JSON'
require 'mongoid'
require 'date'

Mongoid.load!("mongoid.yml")

class WeatherData
    include Mongoid::Document
    field :date
    field :location
    field :temperature
    field :rainfall
    field :wind
    field :cloud
end

def location_id
    {   :bristol => 310004,
        :cambridge => 310042,
        :london => 350928}
end

def daily_forecast(location)
    id = location_id[location.downcase.to_sym]
    url = "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/#{id}?res=3hourly&key=0da4e1ea-8681-47bc-a5f9-5ab535ff75f2"
    resp = Net::HTTP.get_response(URI.parse(url))
    data = resp.body
    result = JSON.parse(data)
    tomorrow = result["SiteRep"]["DV"]["Location"]["Period"][1]["Rep"]

    @temp_tomorrow=[]
    tomorrow.each do |f|
        @temp_tomorrow << f["F"].to_i
    end
    @cloud_tomorrow=[]
    tomorrow.each do |f|
        @cloud_tomorrow << f["V"].to_i
    end
    @rain_tomorrow=[]
    tomorrow.each do |f|
        @rain_tomorrow << f["Pp"].to_i
    end
    @wind_tomorrow=[]
    tomorrow.each do |f|
        @wind_tomorrow << f["S"].to_i
    end

    tomorrow = WeatherData.new 
        tomorrow.date = [DateTime.now.year, DateTime.now.month, DateTime.now.day+1]
        tomorrow.location = location
        tomorrow.temperature = @temp_tomorrow
        tomorrow.rainfall = @rain_tomorrow
        tomorrow.wind = @wind_tomorrow
        tomorrow.cloud = @cloud_tomorrow
    tomorrow.save
end

daily_forecast("bristol")
daily_forecast("cambridge")
daily_forecast("london")


