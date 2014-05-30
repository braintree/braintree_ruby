# Braintree Pay with PayPal

## Overview

This document will walk through creating a simple app that adds a 
Pay with PayPal button ![Pay with PayPal](https://www.paypalobjects.com/webstatic/en_US/btn/btn_pponly_142x27.png)
to your checkout page.  The button launches a lightbox which will take the user through their
PayPal login, and then write a payment method nonce to an input you provide. You can then use this nonce to complete 
the transaction with Braintree.  

### Checkout Flow for Pay with PayPal

![Checkout Flow](https://s3.amazonaws.com/bt-pwpp-beta-docs/PwPP-Docs-Checkout-Flow.png)

### Future Payments UI Flow  

This is the default Pay with PayPal flow, giving you the ability to vault and re-use 
a users' PayPal account info.  

After clicking the Pay with PayPal button on your checkout form, a user is presented with a lightbox  

![Pay with PayPal lightbox](https://s3.amazonaws.com/bt-pwpp-beta-docs/bt-pwpp-login.png).  

On successful authentication, they are then asked to provide consent to allow future payments.
![Pay with PayPal Terms of Service](https://s3.amazonaws.com/bt-pwpp-beta-docs/bt-pwpp-agree.png).  

When the user clicks "agree", the modal closes and writes the paypal authentication data 
to an input that you provided, which can then be used in your Transaction.Sale call to Braintree.

### One Time Payments Flow

In the one time payment flow the user does not give you the extended permissions to store and re-use
their PayPal account information.

The one time flow includes the same login form as described in the previous step, but
the user is not prompted to allow future payments.  Instead the lightbox closes immediately
after a successful login, and writes the payment method nonce
to the input that you provided, which can then be used in your Transaction.Sale call.

### Logout Button

In either flow, after a successful authentication the Pay with PayPal button will be replaced
with a button indicating the PayPal account the user has logged in to, followed by an 'X' logout button.

![Logged in PayPal button](https://s3.amazonaws.com/bt-pwpp-beta-docs/bt-pwpp-logout.png) 

Clicking the logout button resets the checkout form to it's initial state by removing the 
payment method nonce from the input field, and replacing the logout button with the
Pay with PayPal button.

### Use of Email

Once the PayPal transaction is created via Braintree, the user's PayPal account will be identified with 
their email. Per the [PayPal Privacy Policy](https://www.paypal.com/us/webapps/mpp/ua/privacy-full) you may not use this 
email for any purpose other than identifying the user's PayPal account and associated transactions.

## Implementation

### Credentials

Make sure you are pointed at the Braintree `sandbox` environment.
```ruby
Braintree::Configuration.environment = :sandbox
```

At the UI layer, when you are testing you may pass any username and password combination
to proceed with a Sandbox PayPal transaction.

### Update your gemfile 

Change your gemfile to point to the BT Pay with PayPal beta gem.
```ruby
gem 'braintree', :path => 'path/to/bt/beta/gem'
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
    <script type="text/javascript" src="https://js.braintreegateway.com/pwpp/beta/braintree-paypal.js"></script>
  </head>
  <body>

    <form id="merchant-form" action="/create-transaction" method="post">
      <input type="text" name="payment_method_nonce" id="payment-method-nonce" />
      <div id="paypal-container"></div>
      <input type="submit" value="Submit" />
    </form>

    <script type="text/javascript">
      braintree.paypal.create(
        <%= @client_token %>,
        {
          container: "paypal-container",  // to specify DOM elements, use an ID, a DOM node, or a jQuery element
          paymentMethodNonceInputField: "payment-method-nonce"
        }
      );
    </script>

  </body>
</html>
```

The call to `Braintree.PayPal.create` will place the Pay with PayPal button inside the div you provided, 
(`#paypal-container`, in this case), and open a lightbox when the user clicks Pay with PayPal.  

Once the user has completed the authentication with PayPal inside the lightbox, a nonce is written to 
the input you provided, (`#payment-method-nonce`, in this case).  You can use this nonce with your server side call
to `Braintree::Transaction.sale` in order to complete the checkout.  

### Checkout  

Here's the final server side code to complete the transaction; in our Sinatra app, this 
route accepts the post from the form defined above.

```ruby
post "/create-transaction" do
  result = Braintree::Transaction.sale(
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
By default, the Pay with PayPal lightbox will take a user through the future payments flow, which grants you
permission to vault their account, just like you would a credit card, and use it again without the 
user having to re-authenticate.  

Pass `singleUse: true` to trigger the one time use flow instead, which will not prompt the user
to permit future charges on their account.  Naturally, this option will not allow you to vault
their information, and if they wish to Pay with PayPal on your site again they would need to 
authenticate again. 

Attempting to vault a payment method nonce that was created with `singleUse: true` will result in a
validation error from the Braintree Gateway. 

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
