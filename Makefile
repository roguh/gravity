NAME := gravity

build:
	cd src ; zip -9 -r ../build/$(NAME)-$(shell date --iso-8601).love ../README.markdown .
