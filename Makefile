.PHONY: console build

console: build
	docker run -it -v="$(PWD):/braintree-ruby" --net="host" braintree-ruby /bin/bash -l -c "bundle install;bash -l"

build:
	docker build -t braintree-ruby .

lint: build
	docker run -it -v="$(PWD):/braintree-ruby" --net="host" braintree-ruby /bin/bash -l -c "bundle install;rake lint"
