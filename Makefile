include Makefile.base.mk

deps:
	pip install -r requirements.txt

build-local:
	chmod +x container/$(DEPLOYMENT_NAME)/train
	chmod +x container/$(DEPLOYMENT_NAME)/serve
	docker build -t $(DEPLOYMENT_NAME):$(BUILD_ID) container --build-arg IMAGE=$(DEPLOYMENT_NAME)
	docker tag $(DEPLOYMENT_NAME):$(BUILD_ID) $(DEPLOYMENT_NAME):latest


train-local:
	mkdir -p $(shell pwd)/container/local_test/test_dir/model
	mkdir -p $(shell pwd)/container/local_test/test_dir/output
	rm -rf $(shell pwd)/container/local_test/test_dir/model/*
	rm -rf $(shell pwd)/container/local_test/test_dir/output/*
	docker run -v $(shell pwd)/container/local_test/test_dir:/opt/ml --rm $(DEPLOYMENT_NAME) train

serve-local:
	docker run -v $(shell pwd)/container/local_test/test_dir:/opt/ml -p 8080:8080 --rm $(DEPLOYMENT_NAME) serve

predict-local:
	bash $(shell pwd)/container/local_test/predict.sh $(shell pwd)/container/local_test/payload.json

get-s3-data:
	aws s3 cp  s3://hs-machine-learning-processed-production/inbound-autotag/data/ \
	$(shell pwd)/container/local_test/test_dir/input/data/training/ --recursive --profile ml-prod

test:
	@echo "Not implemented."