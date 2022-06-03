#!/bin/bash

pass=241215
newuser="vladium"

echo "Первоначальная установка и настройка программ и служб linux"

if [ -z "$SUDO_USER" ]; then
    echo "Этот скрипт разрешается запускать только из sudo!";
    exit -1;
fi

DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

apt update -yq && apt upgrade -yq
apt autoremove -y

apt install language-pack-ru -y
echo "ru_RU.UTF-8 UTF-8" | tee -a /etc/locale.gen
dpkg-reconfigure --frontend noninteractive locales
update-locale LANG=ru_RU.UTF-8

apt install samba -y
mkdir /mnt/sda
uuid=`blkid | grep sda | cut -d '"' -f 4`
echo UUID=$uuid  /mnt/sda vfat defaults 0 0 >> /etc/fstab

echo " workgroup = WORKGROUP
    netbios name = ubuntu
    security = user
    map to guest = bad user

interfaces = 127.0.0.0/8 eth0

server role = standalone server
obey pam restrictions = yes

[photo]
  path = /mnt/sda/photo
  valid users = vladium
#  valid users = tasha
  guest ok = no
  writable = yes
  browsable = yes" >> /etc/samba/smb.conf
service smbd restart
ufw allow samba
(echo "$pass"; echo "$pass") | smbpasswd -s -a "$newuser"


apt install nginx -y

systemctl stop nginx
cd /var/www/
git clone https://github.com/kotvickiy/test.vladium.ru.git
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/test.vladium.ru.conf
echo "server {
        listen 80 ;
        listen [::]:80 ;

        root /var/www/test.vladium.ru;

        index index.html index.htm index.nginx-debian.html;

        server_name test.vladium.ru;

        location / {
                try_files \$uri \$uri/ =404;
        }
}
" > /etc/nginx/sites-available/test.vladium.ru.conf
ln -s /etc/nginx/sites-available/test.vladium.ru.conf /etc/nginx/sites-enabled/test.vladium.ru.conf
systemctl start nginx



mkdir /home/vladium/.www
cd /home/vladium/.www/
git clone https://github.com/kotvickiy/vladium.ru.git
cd /home/vladium/.www/vladium.ru/
apt install python3.10-venv -y
python3 -m venv env
. env/bin/activate
pip install -r requirements.txt
touch /etc/nginx/sites-enabled/vladium.ru.conf
echo "server {
    server_name vladium.ru;
    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8000;
    }
}" >> /etc/nginx/sites-enabled/vladium.ru.conf
pip install gunicorn
pip install uvloop
pip install httptools
touch /etc/systemd/system/vladium.ru.service
echo '[Unit]
Description=Gunicorn instance to serve vladium.ru app
After=network.target

[Service]
User=vladium
Group=www-data
WorkingDirectory=/home/vladium/.www/vladium.ru
Environment="'PATH=/home/vladium/.www/vladium.ru/env/bin'"
ExecStart=/home/vladium/.www/vladium.ru/env/bin/gunicorn -w 5 -k uvicorn.workers.UvicornWorker server:app

[Install]
WantedBy=multi-user.target
' >> /etc/systemd/system/vladium.ru.service
nginx -s reload
systemctl enable vladium.ru
systemctl start vladium.ru


echo IPv4dev=$2 >> /home/$newuser/nix/options.conf
echo IPv6dev=$2 >> /home/$newuser/nix/options.conf
echo pivpnPORT=$3  >> /home/$newuser/nix/options.conf
/home/$newuser/nix/install_wg.sh  --unattended /home/$newuser/nix/options.conf
echo "$1" | pivpn add
pivpn list
echo 1 | pivpn -qr
mv /home/vladium/configs/ /home/vladium/.configs/

rm -r /home/$newuser/nix

