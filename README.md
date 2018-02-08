# Braintree Ruby library

The Braintree gem provides integration access to the Braintree Gateway.

# Please Note
**The Payment Card Industry (PCI) Council has [mandated](https://blog.pcisecuritystandards.org/migrating-from-ssl-and-early-tls) that early versions of TLS be retired from service.  All organizations that handle credit card information are required to comply with this standard. As part of this obligation, Braintree is updating its services to require TLS 1.2 for all HTTPS connections. Braintree will also require HTTP/1.1 for all connections. Please see our [technical documentation](https://github.com/paypal/tls-update) for more information.**

## Dependencies

* builder
* libxml-ruby

## Installation

```ruby
gem install braintree
```

Or add to your Gemfile:

```ruby
gem 'braintree'
```

## Quick Start Example

```ruby
require "rubygems"
require "braintree"

gateway = Braintree::Gateway.new(
  :environment => :sandbox,
  :merchant_id => "your_merchant_id",
  :public_key => "your_public_key",
  :private_key => "your_private_key",
)

result = gateway.transaction.sale(
  :amount => "1000.00",
  :payment_method_nonce => nonce_from_the_client,
  :options => {
    :submit_for_settlement => true
  }
)

if result.success?
  puts "success!: #{result.transaction.id}"
elsif result.transaction
  puts "Error processing transaction:"
  puts "  code: #{result.transaction.processor_response_code}"
  puts "  text: #{result.transaction.processor_response_text}"
else
  p result.errors
end
```

You retrieve your `merchant_id`, `public_key`, and `private_key` when [signing up](https://braintreepayments.com/get-started) for Braintree. Signing up for a sandbox account is easy, free, and instant.

## Bang Methods

Most methods have a bang and a non-bang version (e.g. `gateway.customer.create` and `gateway.customer.create!`).
The non-bang version will either return a `SuccessfulResult` or an `ErrorResult`. The bang version will either return
the created or updated resource, or it will raise a `ValidationsFailed` exception.

Example of using non-bang method:

```ruby
result = gateway.customer.create(:first_name => "Josh")
if result.success?
  puts "Created customer #{result.customer.id}"
else
  puts "Validations failed"
  result.errors.for(:customer).each do |error|
    puts error.message
  end
end
```

Example of using bang method:

```ruby
begin
  customer = gateway.customer.create!(:first_name => "Josh")
  puts "Created customer #{customer.id}"
rescue Braintree::ValidationsFailed
  puts "Validations failed"
end
```

We recommend using the bang methods when you assume that the data is valid and do not expect validations to fail.
Otherwise, we recommend using the non-bang methods.

## More Information

* [Documentation](https://developers.braintreepayments.com/ruby/sdk/server/overview)

## Developing (Docker)

The `Makefile` and `Dockerfile` will build an image containing the dependencies and drop you to a terminal where you can run tests.

```
make
```

## Tests

The unit specs can be run by anyone on any system, but the integration specs are meant to be run against a local development
server of our gateway code.  These integration specs are not meant for public consumption and will likely fail if run on
your system. To run unit tests use rake: `rake test:unit`.

## Suppress Braintree Logs

To suppress logs from Braintree on environments where they are considered noise
(e.g. test) use the following configuration:

```ruby
logger = Logger.new("/dev/null")
logger.level = Logger::INFO
gateway.config.logger = logger
```

## License

See the [LICENSE](https://github.com/braintree/braintree_ruby/blob/master/LICENSE) file for more info.
