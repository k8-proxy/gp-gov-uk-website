#!/bin/bash
source /home/ubuntu/scripts/.env
if [ -f /home/ubuntu/scripts/update_partition_size.sh ]; then
  chmod +x /home/ubuntu/scripts/update_partition_size.sh
  /home/ubuntu/scripts/update_partition_size.sh
fi
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

CREATE_OVA=${CREATE_OVA:-false}
if [[ "$CREATE_OVA" == "true" ]]; then
  # switching to predictable network interfaces naming
  grep "$KERNEL_BOOT_LINE" /etc/default/grub >/dev/null || sed -Ei "s/GRUB_CMDLINE_LINUX=\"(.*)\"/GRUB_CMDLINE_LINUX=\"\1 $KERNEL_BOOT_LINE\"/g" /etc/default/grub

  # remove swap
  swapoff -a && rm -f /swap.img && sed -i '/swap.img/d' /etc/fstab && echo Swap removed

  # update grub
  update-grub
  curl -sSL https://raw.githubusercontent.com/vmware/cloud-init-vmware-guestinfo/master/install.sh | sudo sh -
  # installing the wizard
  install -T /home/ubuntu/scripts/cwizard.sh /usr/local/bin/wizard -m 0755

  # installing initconfig ( for running wizard on reboot )
  cp -f /home/ubuntu/scripts/initconfig.service /etc/systemd/system/initconfigwizard.service
  install -T /home/ubuntu/scripts/initconfig.sh /usr/local/bin/initconfig.sh -m 0755
  systemctl daemon-reload

  # enable initconfig for the next reboot
  systemctl enable initconfigwizard

fi

