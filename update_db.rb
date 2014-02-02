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

    @tomorrow = WeatherData.new 
        @tomorrow.date = [DateTime.now.year, DateTime.now.month, DateTime.now.day+1]
        date_check
        @tomorrow.location = location
        @tomorrow.temperature = @temp_tomorrow
        @tomorrow.rainfall = @rain_tomorrow
        @tomorrow.wind = @wind_tomorrow
        @tomorrow.cloud = @cloud_tomorrow
    @tomorrow.save
end

def date_check
        if DateTime.now.month == 1 && DateTime.now.day == 31
            @tomorrow.date = [DateTime.now.year, 2, 1]
        elsif DateTime.now.month == 2 && DateTime.now.day == 28
            @tomorrow.date = [DateTime.now.year, 3, 1]
        elsif DateTime.now.month == 3 && DateTime.now.day == 31
            @tomorrow.date = [DateTime.now.year, 4, 1]
        elsif DateTime.now.month == 4 && DateTime.now.day == 30
            @tomorrow.date = [DateTime.now.year, 5, 1]
        elsif DateTime.now.month == 5 && DateTime.now.day == 31
            @tomorrow.date = [DateTime.now.year, 6, 1]
        elsif DateTime.now.month == 6 && DateTime.now.day == 30
            @tomorrow.date = [DateTime.now.year, 7, 1]
        elsif DateTime.now.month == 7 && DateTime.now.day == 31
            @tomorrow.date = [DateTime.now.year, 8, 1]
        elsif DateTime.now.month == 8 && DateTime.now.day == 31
            @tomorrow.date = [DateTime.now.year, 9, 1]
        elsif DateTime.now.month == 9 && DateTime.now.day == 30
            @tomorrow.date = [DateTime.now.year, 10, 1]
        elsif DateTime.now.month == 10 && DateTime.now.day == 31
            @tomorrow.date = [DateTime.now.year, 11, 1]
        elsif DateTime.now.month == 11 && DateTime.now.day == 30
            @tomorrow.date = [DateTime.now.year, 12, 1]
        elsif DateTime.now.month == 12 && DateTime.now.day == 31
            @tomorrow.date = [DateTime.now.year, 1, 1]
        else
        end
    return
end

#Used a global variable in date_check @tomorrow but then once this has been 
# altered to correct the date this needs to communicate to daily_forecast

daily_forecast("bristol")
daily_forecast("cambridge")
daily_forecast("london")


