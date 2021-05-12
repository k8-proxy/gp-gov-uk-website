#!/bin/bash
set -eu
DIALOG_OPTS="--ascii-lines --clear --output-fd 1 --input-fd 2"

function install_dialog () {
echo "Installing dialog."
sudo apt install -y dialog 2>/dev/null
echo "Dialog successfully installed"
sleep 1
}

function main_dialog () {
choice=$( dialog $DIALOG_OPTS --menu Wizard -1 -1 5 1 'Configure network' 2 'Change password' )
case "$choice" in
   1)
      choice=$( network_dialog )
      ;;
   2)
      choice=$( chpass_dialog )
      ;;
esac
}

function chpass_dialog () {
npw1=$(dialog $DIALOG_OPTS --ok-label "Submit" --insecure --passwordbox "New password for $USER" 0 0 )
npw2=$(dialog $DIALOG_OPTS --ok-label "Submit" --insecure --passwordbox "Confirm password for $USER" 0 0 )
echo -e "$npw1\n$npw2" | sudo passwd $USER 2>/dev/null || errorbox "Failed to change password"
}

function network_dialog () {
dialog $DIALOG_OPTS --ok-label "Submit" \
	  --form "Configure network" \
	15 50 0 \
	'IP address v4 (CIDR):' 1 1	"" 	1 22 20 0 \
	"Gateway v4:"		2 1	""  	2 17 15 0 \
	"DNS Nameserver:"	3 1	""  	3 17 15 0 \
| configure_network
}

function configure_network () {
read ip
read gw
read dns
[ -z $ip  ] && return
[ -z $gw  ] && return
[ -z $dns ] && return
if [ "$(ls /etc/netplan/*.yaml /etc/netplan/*.yml 2>/dev/null |  tail -n1 | wc -l)" != 0 ] ; then
[ -d /etc/netplan.backup ] || sudo mkdir -p /etc/netplan.backup
sudo mv /etc/netplan/*.yaml /etc/netplan.backup 2>/dev/null || true
sudo mv /etc/netplan/*.yml /etc/netplan.backup 2>/dev/null || true
fi
ifname=`ip l | awk '/^[1-9]/ {sub(":","",$2);if ($2=="lo") next; print $2;nextfile}'`
sudo tee /etc/netplan/$(date +%F-%H_%M).yaml <<EOF >/dev/null
network:
  version: 2
  ethernets:
    $ifname:
      addresses:
      - $ip
      nameservers:
        addresses:
        - $dns
      gateway4: $gw
      dhcp4: false
EOF
sudo cp /etc/netplan.backup/20-internal-network.yaml /etc/netplan/
sudo netplan generate 2>/dev/null && sudo netplan apply  2>/dev/null || errorbox "Configuration error"
}

function errorbox () {
dialog $DIALOG_OPTS --msgbox "$1" 0 0
}

 
which dialog || install_dialog
true
while [ "$?" == "0" ] ; do
main_dialog
clear
done

clear
