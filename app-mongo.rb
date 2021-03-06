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

def location_id
    {   :bristol => 310004,
        :cambridge => 310042,
        :london => 350928}
end

# Gets the day's data and adds it to the WeatherData class on MongoDB
# Perhaps need a check to see whether today's data has been fetched or not?

# heroku run irb
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
        tomorrow.date = [Date.today.next_day.year, Date.today.next_day.month, Date.today.next_day.day]
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

def get_word_temperature(average)
    if average > 0
        word = "hotter than"
    elsif average    < 0 
        word = "colder than"
    else 
        word = "about the same temperature as"
    end
end

def get_word_rainfall(average)
    if average > 0
        word = "wetter than"
    elsif average    < 0 
        word = "drier than"
    else 
        word = "as rainy as"
    end
end

def get_word_cloud(average)
    if average > 0
        word = "cloudier than"
    elsif average    < 0 
        word = "clearer than"
    else 
        word = "as cloudy as"
    end
end

def get_word_wind(average)
    if average > 0
        word = "windier than"
    elsif average    < 0 
        word = "less windy than"
    else 
        word = "as windy as"
    end
end

def filter_time_location(location, when_for)
    if location == "bristol" && when_for == "today"
        @day_before = WeatherData.find_by(:date => [(Date.today-1).year, (Date.today-1).month, (Date.today-1).day], :location => "bristol")
        @day_after = WeatherData.find_by(:date => [Date.today.year, Date.today.month, Date.today.day], :location => "bristol")
        @word_one = "Today"
        @word_two = "yesterday"
    elsif location == "bristol" && when_for == "tomorrow"
        @day_before = WeatherData.find_by(:date => [Date.today.year, Date.today.month, Date.today.day], :location => "bristol")
        @day_after = WeatherData.find_by(:date => [Date.today.next_day.year, Date.today.next_day.month, Date.today.next_day.day], :location => "bristol")
        @word_one = "Tomorrow"
        @word_two = "today"
    elsif location == "cambridge" && when_for == "today"
        @day_before = WeatherData.find_by(:date => [(Date.today-1).year, (Date.today-1).month, (Date.today-1).day], :location => "cambridge")
        @day_after = WeatherData.find_by(:date => [Date.today.year, Date.today.month, Date.today.day], :location => "cambridge")
        @word_one = "Today"
        @word_two = "yesterday"
    elsif location == "cambridge" && when_for == "tomorrow"
        @day_before = WeatherData.find_by(:date => [Date.today.year, Date.today.month, Date.today.day], :location => "cambridge")
        @day_after = WeatherData.find_by(:date => [Date.today.next_day.year, Date.today.next_day.month, Date.today.next_day.day], :location => "cambridge")
        @word_one = "Tomorrow"
        @word_two = "today"
    elsif location == "london" && when_for == "today"
        @day_before = WeatherData.find_by(:date => [(Date.today-1).year, (Date.today-1).month, (Date.today-1).day], :location => "london")
        @day_after = WeatherData.find_by(:date => [Date.today.year, Date.today.month, Date.today.day], :location => "london")
        @word_one = "Today"
        @word_two = "yesterday"
    elsif location == "london" && when_for == "tomorrow"
        @day_before = WeatherData.find_by(:date => [Date.today.year, Date.today.month, Date.today.day], :location => "london")
        @day_after = WeatherData.find_by(:date => [Date.today.next_day.year, Date.today.next_day.month, Date.today.next_day.day], :location => "london")
        @word_one = "Tomorrow"
        @word_two = "today"
    else [Date.today.year, Date.today.month, Date.today.day]
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
    @comparison_phrase = get_word_temperature(c)
    puts @comparison_phrase
end

def compare_the_rainfall
    combination = @day_before.rainfall.zip(@day_after.rainfall)
    @temp_today = @day_before.rainfall
    @temp_tomorrow = @day_after.rainfall
    c = combination.reduce(0) {|acc,h| acc += compare(h[0],h[1])}
    puts c
    @comparison_phrase = get_word_rainfall(c)
    puts @comparison_phrase
end

def compare_the_cloud
    combination = @day_before.cloud.zip(@day_after.cloud)
    @temp_today = @day_before.cloud
    @temp_tomorrow = @day_after.cloud
    c = combination.reduce(0) {|acc,h| acc += compare(h[0],h[1])}
    puts c
    @comparison_phrase = get_word_cloud(c)
    puts @comparison_phrase
end

def compare_the_wind
    combination = @day_before.wind.zip(@day_after.wind)
    @temp_today = @day_before.wind
    @temp_tomorrow = @day_after.wind
    c = combination.reduce(0) {|acc,h| acc += compare(h[0],h[1])}
    puts c
    @comparison_phrase = get_word_wind(c)
    puts @comparison_phrase
end

def update_weather(location)
    #NOT USED ANY MORE
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
    erb :home_extension
end

get '/test' do
    erb :results_test
end

get '/update' do
    f = [Date.today.next_day.year, Date.today.next_day.month, Date.today.next_day.day]
if f != WeatherData.all.last.date
    daily_forecast("bristol")
    daily_forecast("cambridge")
    daily_forecast("london")
    erb :update_complete
else
    erb :update_not_required
end
end

get '/form' do
    erb :form
end

get '/thanks' do
    erb :thanks
end

post'/' do
    @location = params[:location].downcase
    @when_for = params[:when_for].downcase
    filter_time_location(@location, @when_for)
    if params[:submit] == "temperature-button"
        compare_the_temperature
    elsif params[:submit] == "rainfall-button"
        compare_the_rainfall
    elsif params[:submit] == "cloud-button"
        compare_the_cloud
    elsif params[:submit] == "wind-button"
        compare_the_wind
    else @comparison_phrase = "test"
    end
    erb :results_general
end





