require 'httparty'
require 'uri'
require 'json'

class Client


  def load_producer_json
    response = HTTParty.get(URI::encode('http://localhost:9292/producer.json?valid_date=' + Time.now.httpdate))
    if response.success?
      JSON.parse(response.body)
    end
  end

  def process_data
    data = load_producer_json
    ap data
    value = data['count'] / 100
    date = Time.parse(data['date'])
    puts value
    puts date
    [value, date]
  end

end