#!/bin/bash

source "$HOME/.rvm/scripts/rvm"

if [ $# -eq 0 ]; then
  bundle exec rake --trace
else
  rvm use $1 --create --install
  gem install bundler
  bundle install
  bundle exec rake _0.8.7_ --trace
fi
