FROM debian:jessie

RUN apt-get update
RUN apt-get -y install gnupg curl procps build-essential libxml2-dev
RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash
RUN bash -l -c "rvm requirements"
RUN bash -l -c "rvm install 2.4.4"
RUN bash -l -c "gem install bundler"

WORKDIR /braintree-ruby
