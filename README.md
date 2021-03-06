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

## Step 2 - Pact to the client

Lets setup Pact in the consumer. Pact lets the consumers define the expectations for the integration point.

pact_helper.rb:

```ruby
require 'pact/consumer/rspec'

Pact.service_consumer "Our Consumer" do
  has_pact_with "Our Provider" do
    mock_service :our_provider do
      port 1234
    end
  end
end
```

This defines a consumer and a producer that runs on port 1234.

The spec for the client now replace the previous test by a pact test.

client_spec.rb:

```ruby
describe 'Pact with our provider', :pact => true do

  subject { Client.new('localhost:1234') }

  let(:date) { Time.now.httpdate }

  describe "get json data" do

    before do
        our_provider.
        upon_receiving("a request for json data").
        with(method: :get, path: '/provider.json', query: URI::encode('valid_date=' + date)).
        will_respond_with(
          status: 200,
          headers: {'Content-Type' => 'application/json'},
          body: {
            "test" => "NO",
            "valid_date" => Pact.term(
                generate: "2013-08-16T15:31:20+10:00",
                matcher: /\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2}/)
            }
          )
      end

    it "can process the json payload from the provider" do
      expect(subject.process_data).to eql(Time.parse(json_data['date']))
    end

  end

end
```

Running this spec still passes, but it creates a pact file which we can use to validate our assumptions on the provider side.

```console
    $ rake spec
    /Users/jchuerva/.rvm/rubies/ruby-2.5.3/bin/ruby -I/Users/jchuerva/.rvm/gems/ruby-2.5.3/gems/rspec-core-3.8.0/lib:/Users/jchuerva/.rvm/gems/ruby-2.5.3/gems/rspec-support-3.8.0/lib /Users/jchuerva/.rvm/gems/ruby-2.5.3/gems/rspec-core-3.8.0/exe/rspec --pattern spec/\*\*\{,/\*/\*\*\}/\*_spec.rb

    Client
      Pact with our provider
        get json data
    {
              "test" => "NO",
        "valid_date" => "2013-08-16T15:31:20+10:00"
    }
    2013-08-16 15:31:20 +1000
          can process the json payload from the provider

    Finished in 0.02011 seconds (files took 0.90429 seconds to load)
    1 example, 0 failures
```

Generated pact file (spec/pacts/our_consumer-our_provider.json):

```json
{
  "consumer": {
    "name": "Our Consumer"
  },
  "provider": {
    "name": "Our Provider"
  },
  "interactions": [
    {
      "description": "a request for json data",
      "request": {
        "method": "get",
        "path": "/provider.json",
        "query": "valid_date=Tue,%2030%20Apr%202019%2011:11:42%20GMT"
      },
      "response": {
        "status": 200,
        "headers": {
          "Content-Type": "application/json"
        },
        "body": {
          "test": "NO",
          "valid_date": "2013-08-16T15:31:20+10:00"
        },
        "matchingRules": {
          "$.body.valid_date": {
            "match": "regex",
            "regex": "\\d{4}\\-\\d{2}\\-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\+\\d{2}:\\d{2}"
          }
        }
      }
    }
  ],
  "metadata": {
    "pactSpecification": {
      "version": "2.0.0"
    }
  }
}
```

## Step 3 - Verify pact against provider

Pact has a rake task to verify the producer against the generated pact file. It can get the pact file from any URL (like the last successful CI build), but we just going to use the local one. Here is the addition to the Rakefile.

Rakefile:

```ruby
require 'pact/tasks'
```

spec/pact_helper.rb:

```ruby
require 'pact/provider/rspec'

Pact.service_provider "Our Provider" do

  honours_pact_with 'Our Consumer' do
    pact_uri 'spec/pacts/our_consumer-our_provider.json'
  end

end
```

Checking the rake tasks, we have the `pact:verify ` task to verify the `pact` against the provider

```bash
> rake -T  
rake pact:verify                    # Verifies the pact files configured in the pact_helper.rb against this service provider
```

Running the provider verification passes. 

```bash
> rake pact:verify                                                                                                                                                               
SPEC_OPTS='' /Users/jchuerva/.rvm/rubies/ruby-2.5.3/bin/ruby -S pact verify --pact-helper /Users/jchuerva/Documents/GitHub/pact-ruby-example/spec/pact_helper.rb
INFO: Reading pact at spec/pacts/our_consumer-our_provider.json

Verifying a pact between Our Consumer and Our Provider
  A request for json data
    with GET /provider.json?valid_date=Mon,%2011%20Mar%202019%2018:35:32%20GMT
      returns a response which
        has status code 200
        has a matching body
        includes headers
          "Content-Type" which equals "application/json"

1 interaction, 0 failures
```

## Step 4 - Verify pact still valid after change in provider

Provider include a new field in the answer (eg: field used in other microservice)

```ruby
JSON.pretty_generate({
  :test => 'NO',
  :valid_date => DateTime.now, 
  :blablabla => "new field"
})
```

The contract client-provider in this example should remains valid, since the client is not affected by this new field.

Running the contract tests:
```bash
> rake pact:verify
SPEC_OPTS='' /Users/jchuerva/.rvm/rubies/ruby-2.5.3/bin/ruby -S pact verify --pact-helper /Users/jchuerva/Documents/GitHub/pact-ruby-example/spec/pact_helper.rb
INFO: Reading pact at spec/pacts/our_consumer-our_provider.json

Verifying a pact between Our Consumer and Our Provider
  A request for json data
    with GET /provider.json?valid_date=Mon,%2011%20Mar%202019%2018:35:32%20GMT
      returns a response which
        has status code 200
        has a matching body
        includes headers
          "Content-Type" which equals "application/json"

1 interaction, 0 failures
```

Awesome, we are all done. :tada:
