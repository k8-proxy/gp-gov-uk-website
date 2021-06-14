#!/bin/bash
set -e

pushd $( dirname $0 )
if [ -f ./env ] ; then
source ./env
fi
source ./get_sdk_version.sh
while [[ "$status" != "0" ]]; do echo "Waiting for Kubernetes service" && sleep 5; kubectl get ns; status=$?; done
git clone https://github.com/k8-proxy/icap-infrastructure.git -b k8-main && cd icap-infrastructure
git clone https://github.com/filetrust/icap-infrastructure.git -b main /tmp/icap-infrastructure-sow
cp /tmp/icap-infrastructure-sow/adaptation/values.yaml adaptation/
cp /tmp/icap-infrastructure-sow/administration/values.yaml administration/
cp /tmp/icap-infrastructure-sow/ncfs/values.yaml ncfs/

cd adaptation
requestImage=$(yq eval '.imagestore.requestprocessing.tag' values.yaml)
requestRepo=$(yq eval '.imagestore.requestprocessing.repository' values.yaml)
get_sdk_version filetrust/icap-request-processing $requestImage
docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
docker pull $requestRepo:$requestImage
docker tag $requestRepo:$requestImage localhost:30500/icap-request-processing:$requestImage
docker push localhost:30500/icap-request-processing:$requestImage
docker logout
helm upgrade adaptation --timeout 10m --values custom-values.yaml --install . --namespace icap-adaptation \
    --set imagestore.requestprocessing.registry='localhost:30500/' \
	--set imagestore.requestprocessing.repository='icap-request-processing' \
    --set imagestore.requestprocessing.tag=$requestImage