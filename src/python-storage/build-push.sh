#!/bin/bash

docker build -t acrcapplabgbodev02.azurecr.io/capp/python-storage:latest .
docker push acrcapplabgbodev02.azurecr.io/capp/python-storage:latest