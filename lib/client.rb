require 'httparty'
require 'uri'
require 'json'

class Client

  attr_accessor :base_uri

  def initialize(uri = 'localhost:9292')
    @base_uri = uri
  end

  def load_provider_json(query_date)
    response = HTTParty.get(URI::encode("http://#{base_uri}/provider.json?valid_date=#{query_date}"))
    if response.success?
      JSON.parse(response.body)
    end
  end

  def process_data(query_date)
    data = load_provider_json(query_date)
    ap data
    if data
      date = Time.parse(data['valid_date'])
      puts date
      date
    else
      nil
    end
  end

end
