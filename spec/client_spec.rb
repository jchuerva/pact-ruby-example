require 'spec_helper'
require 'client'

describe Client do

  let(:json_data) do
    {
      "test" => "NO",
      "valid_date" => "2013-08-16T15:31:20+10:00"
    }
  end
  let(:response) { double('Response', :success? => true, :body => json_data.to_json) }

  it 'can process the json payload from the provider' do
    allow(HTTParty).to receive(:get).and_return(response)
    expect(subject.process_data(Time.now.httpdate)).to eql(Time.parse(json_data['valid_date']))
  end
end