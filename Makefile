NAME := gravity
BUILD_NAME := $(NAME)-$(shell date --iso-8601).love

.PHONY: build test

build:
	cd src ; zip -9 -r ../build/$(BUILD_NAME) ../README.markdown .

run: build
	love ./build/$(BUILD_NAME)

lint:
	luacheck src/ --no-color
