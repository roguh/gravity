NAME := gravity
BUILD_NAME := $(NAME)-$(shell date --iso-8601).love

.PHONY: build test

build:
	cd src ; zip -9 -r ../build/$(BUILD_NAME) ../README.markdown .

run: build
	love ./build/$(BUILD_NAME)

run-loop:
	# Useful for testing as you change the code. Simply close the window to re-lint and restart.
	while make lint run ; do true ; done

lint:
	luacheck src/ --no-color
