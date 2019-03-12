Example Ruby Project for Pact
======================================

When writing a lot of small services, testing the interactions between these becomes a major headache. That's the problem Pact is trying to solve.

Integration tests typically are slow and brittle, requiring each component to have it's own environment to run the tests in. With a micro-service architecture, this becomes even more of a problem. They also have to be 'all-knowing' and this makes them difficult to keep from being fragile.

Pact is a ruby gem that allows you to define a pact between service consumers and providers. It provides a DSL for service consumers to define the request they will make to a service producer and the response they expect back. This expectation is used in the consumers specs to provide a mock producer, and is also played back in the producer specs to ensure the producer actually does provide the response the consumer expects.

This allows you to test both sides of an integration point using fast unit tests.

## Step 1 - Simple customer calling Provider

Given we have a client that needs to make a HTTP GET request to a sinatra webapp, and requires a response in JSON format. 

The **client** would look something like:

client.rb:

```ruby
    require 'httparty'
    require 'uri'
    require 'json'

    class Client


      def load_provider_json
        response = HTTParty.get(URI::encode('http://localhost:8081/provider.json?valid_date=' + Time.now.httpdate))
        if response.success?
          JSON.parse(response.body)
        end
      end


    end
```

and the **provider**:

provider.rb

```ruby
    require 'sinatra/base'
    require 'json'


    class Provider < Sinatra::Base


      get '/provider.json', :provides => 'json' do
        valid_time = Time.parse(params[:valid_date])
        JSON.pretty_generate({
          :test => 'NO',
          :valid_date => DateTime.now
        })
      end

    end
```

This provider expects a valid_date parameter in HTTP date format, and then returns some simple json back.

Add a spec to test this client:

client_spec.rb:

```ruby
    require 'spec_helper'
    require 'client'


    describe Client do


      let(:json_data) do
        {
          "test" => "NO",
          "date" => "2013-08-16T15:31:20+10:00"
        }
      end
      let(:response) { double('Response', :success? => true, :body => json_data.to_json) }


      it 'can process the json payload from the provider' do
        HTTParty.stub(:get).and_return(response)
        expect(subject.process_data).to eql(Time.parse(json_data['date']))
      end

    end
```

Let's run this spec and see it all pass:

```console
    $ rake spec
    /home/ronald/.rvm/rubies/ruby-2.3.0/bin/ruby -I/home/ronald/.rvm/gems/ruby-2.3.0@example_pact/gems/rspec-core-3.4.3/lib:/home/ronald/.rvm/gems/ruby-2.3.0@example_pact/gems/rspec-support-3.4.1/lib /home/ronald/.rvm/gems/ruby-2.3.0@example_pact/gems/rspec-core-3.4.3/exe/rspec --pattern spec/\*\*\{,/\*/\*\*\}/\*_spec.rb

    Client
    {
         "test" => "NO",
         "date" => "2013-08-16T15:31:20+10:00"
    }
    2013-08-16 15:31:20
      can process the json payload from the provider

    Finished in 0.00582 seconds (files took 0.09577 seconds to load)
    1 example, 0 failures
```

Running the integration test between client-provider works nicely:

```console
puma config.ru
```

integration_spec.rb

```ruby
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
```
Let's run this spec and see it all pass

```console
client request
{
          "test" => "NO",
    "valid_date" => "2019-03-12T10:05:56+01:00"
}
"NO"
"2019-03-12T10:05:56+01:00"
  integration test

Finished in 0.01538 seconds (files took 0.53142 seconds to load)
1 example, 0 failures
```
