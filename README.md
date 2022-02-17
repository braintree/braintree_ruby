# Braintree Ruby library

The Braintree gem provides integration access to the Braintree Gateway.

# Please Note
**The Payment Card Industry (PCI) Council has [mandated](https://blog.pcisecuritystandards.org/migrating-from-ssl-and-early-tls) that early versions of TLS be retired from service.  All organizations that handle credit card information are required to comply with this standard. As part of this obligation, Braintree is updating its services to require TLS 1.2 for all HTTPS connections. Braintree will also require HTTP/1.1 for all connections. Please see our [technical documentation](https://github.com/paypal/tls-update) for more information.**

## Installation

```ruby
gem install braintree
```

Or add to your Gemfile:

```ruby
gem 'braintree'
```

Optionally, you may also include LibXML for more performant XML parsing. If LibXML is not present, REXML will be used instead.

```ruby
gem 'libxml-ruby'
```

## Dependencies

* builder

The Braintree Ruby SDK is tested against Ruby versions 2.6, 2.7 and 3.0.

_The Ruby core development community has released [End-of-Life branches](https://www.ruby-lang.org/en/downloads/branches/) for Ruby versions lower than 2.6, which are no longer receiving security updates. As a result, Braintree no longer supports these versions of Ruby. **We have updated our gem specifications to reflect these updates.**_

## Versions

Braintree employs a deprecation policy for our SDKs. For more information on the statuses of an SDK check our [developer docs](https://developer.paypal.com/braintree/docs/reference/general/server-sdk-deprecation-policy). [Minimum supported versions](https://developer.paypal.com/braintree/docs/reference/general/best-practices/ruby#server-sdk-versions) are also available in our developer docs.

| Major version number | Status      | Released      | Deprecated   | Unsupported  |
| -------------------- | ----------- | ------------- | ------------ | ------------ |
| 4.x.x                | Active      | May 2021      | TBA          | TBA          |
| 3.x.x                | Inactive    | October 2020  | May 2023     | May 2024     |
| 2.x.x                | Inactive    | April 2010    | October 2022 | October 2023 |

## Documentation

* [Official documentation](https://developer.paypal.com/braintree/docs/start/hello-server/ruby)

Updating from an Inactive, Deprecated, or Unsupported version of this SDK? Check our [Migration Guide](https://developer.paypal.com/braintree/docs/reference/general/server-sdk-migration-guide/ruby) for tips.

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

## Developing (Docker)

The `Makefile` and `Dockerfile` will build an image containing the dependencies and drop you to a terminal where you can run tests.

```
make
```

## Linting

The Rakefile includes commands to run [Rubocop](https://github.com/rubocop/rubocop). To run the linter commands use rake: `rake lint`.

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
