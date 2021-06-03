#!/bin/bash
sleep 10
clear
echo "

Initial configuration

"

#nowe haslo dla uzytkownika glasswall
/usr/local/bin/wizard

systemctl disable initconfigwizard

reboot
exit
