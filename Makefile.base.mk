BUILD_ID := $(shell git rev-parse --short HEAD 2>/dev/null || echo no-commit-id)
WORKSPACE := $(shell pwd)
DEPLOYMENT_NAME := autotag

# Names and locations for images/endpoints and S3 artifacts.
S3_OUTPUT := s3://hs-machine-learning-processed-production/inbound-autotag/sm-output
S3_INPUT := s3://hs-machine-learning-processed-production/inbound-autotag/data
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
	
deploy-dev:
	@echo "Not Implemented"

deploy-staging:
	@echo "Not Implemented"

train:
	aws sagemaker create-training-job --region $(AWS_REGION) \
	--training-job-name $(DEPLOYMENT_NAME)-$(BUILD_ID) \
	--hyper-parameters file://sagemaker/hyperparameters.json \
	--algorithm-specification TrainingImage=$(IMAGE_NAME),\
	TrainingInputMode="File" \
	--role-arn $(ROLE) \
	--input-data-config 'ChannelName=training,DataSource={S3DataSource={S3DataType=S3Prefix,S3Uri=$(S3_INPUT),S3DataDistributionType=FullyReplicated}},ContentType=string,CompressionType=None,RecordWrapperType=None' \
	--output-data-config S3OutputPath=$(S3_OUTPUT) \
	--resource-config file://sagemaker/train-resource-config.json \
	--stopping-condition file://sagemaker/stopping-conditions.json
	
create-model:
	aws sagemaker create-model --region $(AWS_REGION) \
	--model-name $(DEPLOYMENT_NAME)-$(BUILD_ID) \
	--primary-container Image=$(LATEST_IMAGE),\
	ModelDataUrl=$(S3_OUTPUT)/$(DEPLOYMENT_NAME)-$(BUILD_ID)/output/model.tar.gz \
	--execution-role-arn $(ROLE)

create-endpoint-config:
	aws sagemaker create-endpoint-config --region $(AWS_REGION) \
	--endpoint-config-name $(ENDPOINT_CONFIG_NAME) \
	--production-variants VariantName=$(DEPLOYMENT_NAME)-$(BUILD_ID),\
	ModelName=$(DEPLOYMENT_NAME)-$(BUILD_ID),\
	InitialInstanceCount=1,\
	InstanceType="ml.c4.2xlarge",\
	InitialVariantWeight=1.0

create-endpoint:
	aws sagemaker create-endpoint --region $(AWS_REGION) \
	--endpoint-name $(DEPLOYMENT_NAME) \
	--endpoint-config-name $(ENDPOINT_CONFIG_NAME)

test-endpoint:
	@aws sagemaker-runtime invoke-endpoint --body file://container/local_test/payload.json \
	--endpoint-name $(DEPLOYMENT_NAME) \
	--content-type application/json \
	--accept application/json \
	output.json
	@cat output.json

monitor-training-job:
	python ./sagemaker/monitor_job.py training-job \
	--job_name $(DEPLOYMENT_NAME)-$(BUILD_ID) \
	--region $(AWS_REGION)

monitor-endpoint-status:
	python ./sagemaker/monitor_job.py endpoint \
	--job_name $(DEPLOYMENT_NAME) \
	--region $(AWS_REGION)


