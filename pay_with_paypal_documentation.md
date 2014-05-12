## Braintree Pay with PayPal express checkout


This document will walk through creating a simple app that adds a 
Pay with PayPal button ![Pay with PayPal](https://www.paypalobjects.com/webstatic/en_US/btn/btn_pponly_142x27.png)
to your checkout page.  The button launches a lightbox which will take the user through their
PayPal login, and then write a token to an input you provide that you may use to complete 
the checkout with Braintree.  

### Credentials

Make sure you are pointed at the Braintree `sandbox` environment.
```ruby
Braintree::Configuration.environment = :qa
```

You can use this PayPal account for testing from the UI layer.
```
email: bt_buyer_us@paypal.com
password: 11111111
```

### Update your gemfile to point to the BT Pay with PayPal beta gem.

in your Gemfile
```ruby
gem 'braintree', :git => 'git@github.com:braintree/braintree_ruby_paypal_beta.git'
```

And `bundle install` to install the Braintree gem.

### Render your checkout page

Before rendering your checkout page, you will need to insert a call to the Braintree API to retreive a `ClientToken`;
The `ClientToken` is generated on your server, and then used for authentication from the browser to Braintree. 
You'll need to include it when you instantiate the `Braintree.PayPal` client on your checkout page.

Here's what generating the `ClientToken` might look like in a Sinatra app:  
```ruby
get "/checkout_page" do
  @client_token = Braintree::ClientToken.generate
  erb :checkout_page
end
```

And here's what a full checkout page might look like, including instantiating 
the `Braintree.PayPal` client using the `@client_token` variable we created in the previous step:  

```html
<!DOCTYPE html
<html>        
  <head>
    <script type="text/javascript" src="https://assets.stq.braintreepayments.com/pwpp/beta/braintree-paypal.js"></script>
  </head>
  <body>
    
    <form id="merchant-form" action="/create-transaction" method="post">
      <input type="text" name="payment_method_nonce" id="payment-method-nonce" />
      <div id="paypal-container"></div>
      <input type="submit" value="Submit" />
    </form>
    
    <script type="text/javascript">
      Braintree.PayPal.create({
        clientToken: <%= @client_token %>,
        container: "paypal-container",  // to specify DOM elements, use an ID, a DOM node, or a jQuery element
        paymentMethodNonceInputField: "payment-method-nonce"
      });
    </script>
    
  </body>
</html>
```

The call to `Braintree.PayPal.create` will place the Pay with PayPal button inside the div you provided, 
(`#paypal-container`, in this case), and open a lightbox when the user clicks Pay with PayPal.  

Once the user has completed the authentication with PayPal inside the lightbox, a token is written to 
the input you provided, (`#payment-method-nonce`, in this case).  You can use this token with your server side call
to `Braintree::Transaction.sale` in order to complete the checkout.  

### Checkout  

Here's the final server side code to complete the checkout; in our Sinatra app, this 
route accepts the post from the form defined above.

```ruby
post "/create-transaction" do
  result = Braintree::Transaction.sale(
     # we need to specify a merchant account with paypal enabled
    :merchant_account_id => 'altpay_merchant_paypal_merchant_account',
    :amount => "10.00",
    :payment_method_nonce => params[:payment_method_nonce],
  )
  if result.success?
    "Success ID: #{result.transaction.id}"
  else
    result.message
  end
end
```  

### Other `Braintree.PayPal.create` Options

#### singleUse  
By default, the PwPP lightbox will take a user through the future payments flow, which grants you
permission to vault their account, just like you would a credit card, and use it again without the 
user having to re-authenticate.  

Pass `singleUse: true` to trigger the one time use flow instead, which will not prompt the user
to permit future charges on their account.  Naturally, this option will not allow you to vault
their information, and if they wish to Pay with PayPal on your site again they would need to 
authenticate again.  

#### callbacks
You can register a success callback if you wish to perform any UI treatments once the user has completed authenticating 
with PayPal through the lightbox.
```javascript  
Braintree.PayPal.create({
  clientToken: <%= @client_token %>,
  container: "paypal-container",
  input: "payment-method-nonce",
  onSuccess: function () {
    alert("Thanks for entering your PayPal information! Click 'Submit' to checkout");
  }
});
```  

An `onUnsupported` function can be used to handle older browsers and non HTTPS protocols.

```javascript
Braintree.PayPal.create({
  ...
  onUnsupported: function () {
    alert("Your browser is unsupported");
  }
});
```

#### input  
If you wish, you may omit the `input:` argument, and `Braintree.PayPal.create` will create a hidden input for you
inside of your given `container` element.  
