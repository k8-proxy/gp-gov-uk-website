#!/bin/bash
set -e
source /home/ubuntu/scripts/.env
if [ -f /home/ubuntu/scripts/update_partition_size.sh ]; then
  chmod +x /home/ubuntu/scripts/update_partition_size.sh
  /home/ubuntu/scripts/update_partition_size.sh
fi

apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
# install local docker registry
docker run -d -p 127.0.0.1:30500:5000 --restart always --name registry registry:2
docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
git clone https://github.com/k8-proxy/icap-infrastructure.git -b k8-main && cd icap-infrastructure

cd rabbitmq
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm upgrade rabbitmq --install . --namespace icap-adaptation
cd ..
cat >>openssl.cnf <<EOF
[ req ]
prompt = no
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
C = GB
ST = London
L = London
O = Glasswall
OU = IT
CN = icap-server
emailAddress = admin@glasswall.com
EOF
openssl req -newkey rsa:2048 -config openssl.cnf -nodes -keyout /tmp/tls.key -x509 -days 365 -out /tmp/certificate.crt
kubectl create secret tls icap-service-tls-config --namespace icap-adaptation --key /tmp/tls.key --cert /tmp/certificate.crt

# Clone ICAP SOW Version
git clone https://github.com/filetrust/icap-infrastructure.git -b main /tmp/icap-infrastructure-sow
cp /tmp/icap-infrastructure-sow/adaptation/values.yaml adaptation/
cp /tmp/icap-infrastructure-sow/administration/values.yaml administration/
cp /tmp/icap-infrastructure-sow/ncfs/values.yaml ncfs/

cd adaptation
snap install yq
kubectl create -n icap-adaptation secret generic policyupdateservicesecret --from-literal=username=policy-management --from-literal=password='long-password'
kubectl create -n icap-adaptation secret generic transactionqueryservicesecret --from-literal=username=query-service --from-literal=password='long-password'
kubectl create -n icap-adaptation secret generic rabbitmq-service-default-user --from-literal=username=guest --from-literal=password='guest'
if [[ "${ICAP_FLAVOUR}" == "classic" ]]; then
	requestImage=$(yq eval '.imagestore.requestprocessing.tag' custom-values.yaml)
	requestRepo=$(yq eval '.imagestore.requestprocessing.repository' custom-values.yaml)
	docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
	docker pull $requestRepo:$requestImage
	docker tag $requestRepo:$requestImage localhost:30500/icap-request-processing:$requestImage
	docker push localhost:30500/icap-request-processing:$requestImage
	helm upgrade adaptation --values custom-values.yaml --install . --namespace icap-adaptation  --set imagestore.requestprocessing.registry='localhost:30500/' \
	--set imagestore.requestprocessing.repository='icap-request-processing'
fi

if [[ "${ICAP_FLAVOUR}" == "golang" ]]; then
	helm upgrade adaptation --values custom-values.yaml --install . --namespace icap-adaptation
	# Install minio
	kubectl create ns minio
	kubectl create ns jaeger
	helm repo add minio https://helm.min.io/
	helm install -n minio --set accessKey=minio,secretKey=$MINIO_SECRET,buckets[0].name=sourcefiles,buckets[0].policy=none,buckets[0].purge=false,buckets[1].name=cleanfiles,buckets[1].policy=none,buckets[1].purge=false,fullnameOverride=minio-server,persistence.enabled=false minio/minio --generate-name
	kubectl create -n icap-adaptation secret generic minio-credentials --from-literal=username='minio' --from-literal=password=$MINIO_SECRET

	# deploy new Go services
	git clone https://github.com/k8-proxy/go-k8s-infra.git -b main && pushd go-k8s-infra

	# Scale the existing adaptation service to 0
	kubectl -n icap-adaptation scale --replicas=0 deployment/adaptation-service
	kubectl -n icap-adaptation delete cronjob pod-janitor
	# Install jaeger-agent
	kubectl apply -f jaeger-agent/jaeger.yaml
	# Apply helm chart to create the services
	helm upgrade servicesv2 --install services --namespace icap-adaptation
	popd
fi


kubectl patch svc frontend-icap-lb -n icap-adaptation --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":1344},{"op":"replace","path":"/spec/ports/1/nodePort","value":1345}]'
cd ..

if [[ "${INSTALL_M_UI}" == "true" ]]; then
  mkdir -p /var/local/rancher/host/c/userstore
  cp -r default-user/* /var/local/rancher/host/c/userstore/
  kubectl create ns management-ui
  kubectl create ns icap-ncfs
  cd ncfs
  kubectl create -n icap-ncfs secret generic ncfspolicyupdateservicesecret --from-literal=username=policy-update --from-literal=password='long-password'
  helm upgrade ncfs --values custom-values.yaml --install . --namespace icap-ncfs
  cd ..
  kubectl create -n management-ui secret generic transactionqueryserviceref --from-literal=username=query-service --from-literal=password='long-password'
  kubectl create -n management-ui secret generic policyupdateserviceref --from-literal=username=policy-management --from-literal=password='long-password'
  kubectl create -n management-ui secret generic ncfspolicyupdateserviceref --from-literal=username=policy-update --from-literal=password='long-password'
  cd administration
  sed -i 's|traefik|nginx|' templates/management-ui/ingress.yml
  helm upgrade administration --values custom-values.yaml --install . --namespace management-ui
  cd ..
  kubectl delete secret/smtpsecret -n management-ui
  kubectl create -n management-ui secret generic smtpsecret \
    --from-literal=SmtpHost=$SMTPHOST \
    --from-literal=SmtpPort=$SMTPPORT \
    --from-literal=SmtpUser=$SMTPUSER \
    --from-literal=SmtpPass=$SMTPPASS \
    --from-literal=TokenSecret='12345678901234567890123456789012' \
    --from-literal=TokenLifetime='00:01:00' \
    --from-literal=EncryptionSecret='12345678901234567890123456789012' \
    --from-literal=ManagementUIEndpoint='http://management-ui:8080' \
    --from-literal=SmtpSecureSocketOptions='http://management-ui:8080'

fi

# Install CS-API
if [[ "${INSTALL_CSAPI}" == "true" ]]; then
  git clone https://github.com/k8-proxy/cs-k8s-api && cd cs-k8s-api
  helm upgrade --install -n icap-adaptation rebuild-api --set k8s_version=1.18 infra/kubernetes/chart  --atomic
fi

# Install Filedrop UI
if [[ "${INSTALL_FILEDROP_UI}" == "true" ]]; then
  INSTALL_CSAPI="true"
  git clone https://github.com/k8-proxy/k8-rebuild.git && cd k8-rebuild
  rm -rf kubernetes/charts/sow-rest-api-0.1.0.tgz
	rm -rf kubernetes/charts/nginx-8.2.0.tgz
	# install helm charts
	helm upgrade --install k8-rebuild -n icap-adaptation --timeout 10m --set nginx.service.type=ClusterIP --atomic kubernetes/ 
fi

docker logout
# defining vars
DEBIAN_FRONTEND=noninteractive
KERNEL_BOOT_LINE='net.ifnames=0 biosdevname=0'

# install needed packages
apt install -y telnet tcpdump open-vm-tools net-tools dialog curl git sed grep fail2ban
systemctl enable fail2ban.service
tee -a /etc/fail2ban/jail.d/sshd.conf <<EOF >/dev/null
[sshd]
enabled = true
port = ssh
action = iptables-multiport
logpath = /var/log/auth.log
bantime  = 10h
findtime = 10m
maxretry = 5
EOF
systemctl restart fail2ban

if [[ "$CREATE_OVA" == "true" ]]; then
  # switching to predictable network interfaces naming
  grep "$KERNEL_BOOT_LINE" /etc/default/grub >/dev/null || sed -Ei "s/GRUB_CMDLINE_LINUX=\"(.*)\"/GRUB_CMDLINE_LINUX=\"\1 $KERNEL_BOOT_LINE\"/g" /etc/default/grub

  # remove swap
  swapoff -a && rm -f /swap.img && sed -i '/swap.img/d' /etc/fstab && echo Swap removed

  # update grub
  update-grub
  curl -sSL https://raw.githubusercontent.com/vmware/cloud-init-vmware-guestinfo/master/install.sh | sh -
  rm -f /etc/cloud/cloud.cfg.d/99-DataSourceVMwareGuestInfo.cfg
	sed -i "s/Ec2/Ec2, VMwareGuestInfo/g" /etc/cloud/cloud.cfg.d/90_dpkg.cfg
  # installing the wizard
  install -T /home/ubuntu/scripts/cwizard.sh /usr/local/bin/wizard -m 0755

  # installing initconfig ( for running wizard on reboot )
  cp -f /home/ubuntu/scripts/initconfig.service /etc/systemd/system/initconfigwizard.service
  install -T /home/ubuntu/scripts/initconfig.sh /usr/local/bin/initconfig.sh -m 0755
  systemctl daemon-reload

  # enable initconfig for the next reboot
  systemctl enable initconfigwizard

fi
