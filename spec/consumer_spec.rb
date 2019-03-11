require 'ap'
require 'consumer'

describe Consumer do

  let(:json_data) do
    {
      "test" => "NO",
      "valid_date" => "2013-08-16T15:31:20+10:00",
      "count" => 100
    }
  end

  let(:response) { double('Response', :success? => true, :body => json_data.to_json) }

  it 'can process the json payload from the producer' do
    allow(HTTParty).to receive(:get).and_return(response)
    expect(subject.process_data(Time.now.httpdate)).to eql([1, Time.parse(json_data['valid_date'])])
  end


end