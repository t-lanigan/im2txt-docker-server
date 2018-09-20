BUILD_ID := $(shell git rev-parse --short HEAD 2>/dev/null || echo no-commit-id)
WORKSPACE := $(shell pwd)
DEPLOYMENT_NAME := autocaption

.PHONY: test

.DEFAULT_GOAL := help
help: ## List targets & descriptions
	@cat $(MAKEFILE_LIST) | sort| perl -ne '/^(\w.*):.*?##\s(.*)/ && printf "\e[36m%-30s\e[0m %s\n", $$1, $$2'

first-run: 
	@echo "Not Implemented" #clean deps deps-test test run ## Run after creating your service!

