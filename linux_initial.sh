#!/bin/bash

pass=241215
newuser="vladium"

echo "Первоначальная установка и настройка программ и служб linux"

if [ -z "$SUDO_USER" ]; then
    echo "Этот скрипт разрешается запускать только из sudo";
    exit -1;
fi

apt update -y && apt upgrade -y
apt autoremove -y

apt install language-pack-ru -y
echo "ru_RU.UTF-8 UTF-8" | tee -a /etc/locale.gen
dpkg-reconfigure --frontend noninteractive locales
update-locale LANG=ru_RU.UTF-8

apt install samba -y
mkdir /mnt/share/
echo "[sambashare]
    comment = Samba on Ubuntu Server
    path = /mnt/share
    read only = no
    browsable = yes" >> /etc/samba/smb.conf
service smbd restart
ufw allow samba
(echo "$pass"; echo "$pass") | smbpasswd -s -a "$newuser"

