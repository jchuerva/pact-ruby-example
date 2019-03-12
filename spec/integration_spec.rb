require 'client'
require 'ap'

$:.unshift 'lib'


RSpec.describe "client request", type: :feature do

  it "integration test", fast: true do
    ap Client.new.load_provider_json(Time.now)

    expect(ap Client.new.load_provider_json(Time.now)['test']).to eql('NO')
    expect(ap Client.new.load_provider_json(Time.now)['valid_date']).to match(/\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2}/)
  end
end