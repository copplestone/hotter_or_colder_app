require 'sinatra'
require 'net/http'
require 'json'
require 'mongoid'
require 'date'

Mongoid.load!("mongoid.yml")
# The :development bit refers to our environment - 
# you will probably want to have different configuration 
# options when you’re deploying your app to heroku; mongoid 
# allows this by specifying :production and :development environments.

class WeatherData
    include Mongoid::Document
    field :date
    field :location
    field :temperature
    field :rainfall
    field :wind
    field :cloud
end


# Models

def update_required(current)
    url = "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/capabilities?res=3hourly&key=0da4e1ea-8681-47bc-a5f9-5ab535ff75f2"
    resp = Net::HTTP.get_response(URI.parse(url))
    data = resp.body
    result = JSON.parse(data)
    most_recent_from_db = "#{WeatherData.first.date[0]}-#{WeatherData.first.date[1]}-#{WeatherData.first.date[2]}"
    most_recent_from_met = result["Resource"]["dataDate"].chop[0..9]
    if  most_recent_from_db != most_recent_from_met
        daily_forecast
    end
    #if result.has_key? 'Error'
    #    raise "web service error"
    #end
    return result
end

def location_id
    {   :bristol => 310004,
        :cambridge => 310042,
        :london => 350928}
end

# Gets the day's data and adds it to the WeatherData class on MongoDB
# Perhaps need a check to see whether today's data has been fetched or not?
def daily_forecast(location)
    id = location_id[location.downcase.to_sym]
    puts id
# Maybe call it weather_update to call at 00:01 every day, needs to iterate over each location
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

def compare (x,y)
    if x>y
        return -1
    elsif x<y
        return 1
    else
        return 0
    end
end

def get_word(average)
    if average > 0
        word = "hotter than"
    elsif average    < 0 
        word = "colder than"
    else 
        word = "about the same as"
    end
end

def filter_time_location(location, when_for)
    if location == "bristol" && when_for == "today"
        @day_before = WeatherData.find_by(:date => [DateTime.now.year, DateTime.now.month, DateTime.now.day-1], :location => "bristol")
        @day_after = WeatherData.find_by(:date => [DateTime.now.year, DateTime.now.month, DateTime.now.day], :location => "bristol")
        @word_one = "Today"
        @word_two = "yesterday"
    elsif location == "bristol" && when_for == "tomorrow"
        @day_before = WeatherData.find_by(:date => [DateTime.now.year, DateTime.now.month, DateTime.now.day], :location => "bristol")
        @day_after = WeatherData.find_by(:date => [DateTime.now.year, DateTime.now.month, DateTime.now.day+1], :location => "bristol")
        @word_one = "Tomorrow"
        @word_two = "today"
    elsif location == "cambridge" && when_for == "today"
        @day_before = WeatherData.find_by(:date => [DateTime.now.year, DateTime.now.month, DateTime.now.day-1], :location => "cambridge")
        @day_after = WeatherData.find_by(:date => [DateTime.now.year, DateTime.now.month, DateTime.now.day], :location => "cambridge")
        @word_one = "Today"
        @word_two = "yesterday"
    elsif location == "cambridge" && when_for == "tomorrow"
        @day_before = WeatherData.find_by(:date => [DateTime.now.year, DateTime.now.month, DateTime.now.day], :location => "cambridge")
        @day_after = WeatherData.find_by(:date => [DateTime.now.year, DateTime.now.month, DateTime.now.day+1], :location => "cambridge")
        @word_one = "Tomorrow"
        @word_two = "today"
    elsif location == "london" && when_for == "today"
        @day_before = WeatherData.find_by(:date => [DateTime.now.year, DateTime.now.month, DateTime.now.day-1], :location => "london")
        @day_after = WeatherData.find_by(:date => [DateTime.now.year, DateTime.now.month, DateTime.now.day], :location => "london")
        @word_one = "Today"
        @word_two = "yesterday"
    elsif location == "london" && when_for == "tomorrow"
        @day_before = WeatherData.find_by(:date => [DateTime.now.year, DateTime.now.month, DateTime.now.day], :location => "london")
        @day_after = WeatherData.find_by(:date => [DateTime.now.year, DateTime.now.month, DateTime.now.day+1], :location => "london")
        @word_one = "Tomorrow"
        @word_two = "today"
    else
        puts "Haven't found data to compare"
    end
    return 
end


def compare_the_temperature
    combination = @day_before.temperature.zip(@day_after.temperature)
    @temp_today = @day_before.temperature
    @temp_tomorrow = @day_after.temperature
    c = combination.reduce(0) {|acc,h| acc += compare(h[0],h[1])}
    puts c
    @h_or_c = get_word(c)
    puts @h_or_c
end


def update_weather(location)
    #convert location into location ID for the URL
    url = "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/[LocationID]?res=3hourly&key=0da4e1ea-8681-47bc-a5f9-5ab535ff75f2"
    resp = Net::HTTP.get_response(URI.parse(url))
    data = resp.body
    result = JSON.parse(data)
    #Take out the useful data, compare it with the current data
    #for today and return hotter, colder or exactly the same.
end

#Controllers
get '/' do
    erb :home
end

get '/test' do
    erb :results_test
end

get '/update' do
    daily_forecast("bristol")
    daily_forecast("cambridge")
    daily_forecast("london")
    puts "Update completed"
end

post'/' do
    @location = params[:location].downcase
    @when_for = params[:when_for].downcase
    filter_time_location(@location, @when_for)
    compare_the_temperature
    erb :results
end

