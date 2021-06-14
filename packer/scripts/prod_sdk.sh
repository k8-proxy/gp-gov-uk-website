#!/bin/bash
set -e

pushd $( dirname $0 )
if [ -f ./env ] ; then
source ./env
fi
source ./get_sdk_version.sh

cd ~/icap-infrastructure/adaptation
requestImage=$(yq eval '.imagestore.requestprocessing.tag' values.yaml)
requestRepo=$(yq eval '.imagestore.requestprocessing.repository' values.yaml)
get_sdk_version filetrust/icap-request-processing $requestImage
sudo docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
sudo docker pull $requestRepo:$requestImage
sudo docker tag $requestRepo:$requestImage localhost:30500/icap-request-processing:$requestImage
sudo docker push localhost:30500/icap-request-processing:$requestImage
sudo docker logout
helm upgrade adaptation --values custom-values.yaml --install . --namespace icap-adaptation \
    --set imagestore.requestprocessing.registry='localhost:30500/' \
	--set imagestore.requestprocessing.repository='icap-request-processing' \
    --set imagestore.requestprocessing.tag=$requestImage