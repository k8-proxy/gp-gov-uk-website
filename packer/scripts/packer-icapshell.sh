#!/bin/bash
source /home/ubuntu/scripts/.env
if [ -f /home/ubuntu/scripts/update_partition_size.sh ] ; then
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
mkdir -p /var/local/rancher/host/c/userstore
cp -r default-user/* /var/local/rancher/host/c/userstore/
#kubectl  create ns icap-adaptation
kubectl  create ns management-ui
kubectl  create ns icap-ncfs
cd rabbitmq
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm upgrade rabbitmq --install . --namespace icap-adaptation 
cd ..
cat >> openssl.cnf <<EOF
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
openssl req -newkey rsa:2048 -config openssl.cnf -nodes -keyout  /tmp/tls.key -x509 -days 365 -out /tmp/certificate.crt
kubectl  create secret tls icap-service-tls-config --namespace icap-adaptation --key /tmp/tls.key --cert /tmp/certificate.crt
# Clone ICAP SOW Version 
git clone https://github.com/filetrust/icap-infrastructure.git -b main /tmp/icap-infrastructure-sow
cp  /tmp/icap-infrastructure-sow/adaptation/values.yaml adaptation/
cp  /tmp/icap-infrastructure-sow/administration/values.yaml administration/
cp  /tmp/icap-infrastructure-sow/ncfs/values.yaml ncfs/
wget https://github.com/mikefarah/yq/releases/download/v4.7.0/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
requestImage=$(yq eval '.imagestore.requestprocessing.tag' adaptation/values.yaml)
docker pull glasswallsolutions/icap-request-processing:$requestImage
docker tag glasswallsolutions/icap-request-processing:$requestImage localhost:30500/icap-request-processing:$requestImage
docker push localhost:30500/icap-request-processing:$requestImage



cd adaptation
kubectl  create -n icap-adaptation secret generic policyupdateservicesecret --from-literal=username=policy-management --from-literal=password='long-password'
kubectl  create -n icap-adaptation secret generic transactionqueryservicesecret --from-literal=username=query-service --from-literal=password='long-password'
kubectl  create -n icap-adaptation secret generic  rabbitmq-service-default-user --from-literal=username=guest --from-literal=password='guest'
kubectl  create -n icap-adaptation secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username="" --docker-password="" --docker-email=""
helm upgrade adaptation --values custom-values.yaml --install . --namespace icap-adaptation --set imagestore.requestprocessing.registry='localhost:30500/' \
--set imagestore.requestprocessing.repository='icap-request-processing'
docker logout
kubectl patch svc frontend-icap-lb -n icap-adaptation --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":1344},{"op":"replace","path":"/spec/ports/1/nodePort","value":1345}]'
cd ..
cd ncfs
kubectl  create -n icap-ncfs secret generic ncfspolicyupdateservicesecret --from-literal=username=policy-update --from-literal=password='long-password'
helm upgrade ncfs --values custom-values.yaml --install . --namespace icap-ncfs
cd ..
kubectl  create -n management-ui secret generic transactionqueryserviceref --from-literal=username=query-service --from-literal=password='long-password'
kubectl  create -n management-ui secret generic policyupdateserviceref --from-literal=username=policy-management --from-literal=password='long-password'
kubectl  create -n management-ui secret generic ncfspolicyupdateserviceref --from-literal=username=policy-update --from-literal=password='long-password'
cd administration
sed -i 's|traefik|nginx|' templates/management-ui/ingress.yml
helm upgrade administration --values custom-values.yaml --install . --namespace management-ui
cd ..
kubectl delete secret/smtpsecret -n management-ui
kubectl  create -n management-ui secret generic smtpsecret \
	--from-literal=SmtpHost=$SMTPHOST \
	--from-literal=SmtpPort=$SMTPPORT \
	--from-literal=SmtpUser=$SMTPUSER \
	--from-literal=SmtpPass=$SMTPPASS \
	--from-literal=TokenSecret='12345678901234567890123456789012' \
	--from-literal=TokenLifetime='00:01:00' \
	--from-literal=EncryptionSecret='12345678901234567890123456789012' \
	--from-literal=ManagementUIEndpoint='http://management-ui:8080' \
	--from-literal=SmtpSecureSocketOptions='http://management-ui:8080'
wget https://raw.githubusercontent.com/k8-proxy/cs-k8s-api/main/deployment.yaml
echo $CS_API_IMAGE
sed -i 's|glasswallsolutions/cs-k8s-api:latest|'$CS_API_IMAGE'|' deployment.yaml
kubectl  apply -f deployment.yaml -n icap-adaptation
kubectl patch svc proxy-rest-api -n icap-adaptation --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":8080}]'

# install filedrop
# get source code
git clone https://github.com/k8-proxy/k8-rebuild.git --branch ck8s-filedrop --recursive && cd k8-rebuild && git submodule update --init --recursive && git submodule foreach git pull origin main && cd k8-rebuild-rest-api && git pull origin main && cd libs/ && git pull origin master && cd ../../
# build images
docker build k8-rebuild-rest-api -f k8-rebuild-rest-api/Source/Service/Dockerfile -t localhost:30500/k8-rebuild-rest-api
docker push localhost:30500/k8-rebuild-rest-api
docker build k8-rebuild-file-drop/app -f k8-rebuild-file-drop/app/Dockerfile -t localhost:30500/k8-rebuild-file-drop
docker push localhost:30500/k8-rebuild-file-drop

cat >> kubernetes/values.yaml <<EOF

sow-rest-api:
  image:
    registry: localhost:30500
    repository: k8-rebuild-rest-api
    imagePullPolicy: Never
    tag: latest
sow-rest-ui:
  image:
    registry: localhost:30500
    repository: k8-rebuild-file-drop
    imagePullPolicy: Never
    tag: latest
EOF

# install UI and API helm charts
helm upgrade --install k8-rebuild \
  --set nginx.service.type=ClusterIP \
  --atomic kubernetes/


# defining vars
DEBIAN_FRONTEND=noninteractive
KERNEL_BOOT_LINE='net.ifnames=0 biosdevname=0'


# install needed packages
apt install -y telnet tcpdump open-vm-tools net-tools dialog curl git sed grep fail2ban
systemctl enable fail2ban.service
tee -a /etc/fail2ban/jail.d/sshd.conf << EOF > /dev/null
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

# switching to predictable network interfaces naming
grep "$KERNEL_BOOT_LINE" /etc/default/grub >/dev/null || sed -Ei "s/GRUB_CMDLINE_LINUX=\"(.*)\"/GRUB_CMDLINE_LINUX=\"\1 $KERNEL_BOOT_LINE\"/g" /etc/default/grub

# remove swap 
swapoff -a && rm -f /swap.img && sed -i '/swap.img/d' /etc/fstab && echo Swap removed

# update grub
update-grub

# installing the wizard
install -T /home/ubuntu/scripts/cwizard.sh /usr/local/bin/wizard -m 0755

# installing initconfig ( for running wizard on reboot )
cp -f /home/ubuntu/scripts/initconfig.service /etc/systemd/system/initconfigwizard.service
install -T /home/ubuntu/scripts/initconfig.sh /usr/local/bin/initconfig.sh -m 0755
systemctl daemon-reload

# enable initconfig for the next reboot
systemctl enable initconfigwizard
