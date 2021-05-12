#!/bin/bash
source /home/ubuntu/packer-scripts/.env
SSH_PASSWORD=${SSH_PASSWORD:-glasswall}
printf "${SSH_PASSWORD}\n${SSH_PASSWORD}" | passwd ubuntu
usermod -U ubuntu
# useradd -m -s /bin/bash glasswall
# usermod -aG sudo glasswall
# printf "${SSH_PASSWORD}\n${SSH_PASSWORD}" | passwd glasswall
sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/lock_passwd.*/lock_passwd: False/g" /etc/cloud/cloud.cfg
service ssh restart
