BUILD_ID := $(shell git rev-parse --short HEAD 2>/dev/null || echo no-commit-id)
WORKSPACE := $(shell pwd)
DEPLOYMENT_NAME := autocaption

# Names and locations for images/endpoints and S3 artifacts.
IMAGE_NAME := 112025830381.dkr.ecr.us-east-1.amazonaws.com/$(DEPLOYMENT_NAME)
LATEST_IMAGE := $(IMAGE_NAME):latest
ENDPOINT_NAME := $(DEPLOYMENT_NAME)-$(BUILD_ID)
ENDPOINT_CONFIG_NAME := $(DEPLOYMENT_NAME)-$(BUILD_ID)-config
AWS_REGION := us-east-1

# Execution role to pass to SageMaker
ROLE := arn:aws:iam::112025830381:role/sagemaker_deploy

.PHONY: test

.DEFAULT_GOAL := help
help: ## List targets & descriptions
	@cat $(MAKEFILE_LIST) | sort| perl -ne '/^(\w.*):.*?##\s(.*)/ && printf "\e[36m%-30s\e[0m %s\n", $$1, $$2'

id: ## Output BUILD_ID being used
	@echo $(BUILD_ID)

debug: ## Output internal make variables
	@echo BUILD_ID = $(BUILD_ID)
	@echo IMAGE_NAME = $(IMAGE_NAME)
	@echo WORKSPACE = $(WORKSPACE)
	@echo ENDPOINT_NAME = $(ENDPOINT_NAME)
	@echo ENDPOINT_CONFIG_NAME = $(ENDPOINT_CONFIG_NAME)
	@echo AWS_REGION = $(AWS_REGION)

first-run: 
	@echo "Not Implemented" #clean deps deps-test test run ## Run after creating your service!

pull: ## Docker pull the latest base image
	docker pull $(BASE_IMAGE_NAME):latest

push: ## docker push the service images tagged 'latest' & 'BUILD_ID'
	docker push $(IMAGE_NAME):$(BUILD_ID)
	docker push $(IMAGE_NAME):latest

build-service:
	chmod +x container/$(DEPLOYMENT_NAME)/train
	chmod +x container/$(DEPLOYMENT_NAME)/serve
	bash container/build_and_push.sh $(DEPLOYMENT_NAME) $(BUILD_ID)
	


