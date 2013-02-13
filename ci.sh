#!/bin/bash

source "$HOME/.rvm/scripts/rvm"

if [ $# -eq 0 ]; then
  rake --trace
else
  rvm use $1 --create --install
  rvm gemset import braintree-ruby.gems
  rake --trace
fi
