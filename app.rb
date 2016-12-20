require 'sinatra'
require 'sinatra/strong-params'
require 'watir'
require 'headless'
require 'nokogiri'
require 'json'
require_relative 'lib/avia_yandex_parser'
require_relative 'lib/deal'
set :show_exceptions, :after_handler # for development

helpers do
  def humanized_details(details)
    "Аэропорты: #{details[:airports]}, #{transfers(details[:transfers])}"
  end
end
def transfers(transfers_array)
  result = ''
  if transfers_array.first.key?(:transfer)
    result = transfers_array.first[:transfer]
  else
    transfers_array.each { |transfer| result += "#{transfer[:place]} - #{transfer[:transfer_duration]}; " }
  end
  result
end

get '/' do
  erb :index
end

get '/results', needs: [:from_name, :to_name, :when, :adult_seats] do
  parser = AviaYandexParser.new(params)
  parser.perform
  @results = parser.results
  erb :results
end

error RequiredParamMissing do
  [400, 'Params missing']
end
