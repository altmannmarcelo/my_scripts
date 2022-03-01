#!/bin/bash

typeset -r weekday=$(date +%w)
typeset -r folder="/home/marcelo/Dropbox/servers/marceloaltmann.com/sf3"

CURRENT_FOLDER=$(pwd)
cd ${folder}/${weekday}
NODE_NAME=marcelo-blog-restore-standalone-1
deploy_lxc --destroy $NODE_NAME
lxc init centos-8 $NODE_NAME -s $(whoami)
deploy_lxc --type=standalone --name=blog-restore
MY_IP=`deploy_lxc --list | grep $NODE_NAME | awk '{print $6}'`
lxc exec $NODE_NAME -- yum install -y epel-release
lxc exec $NODE_NAME -- yum install -y openssl nginx letsencrypt tar
lxc exec $NODE_NAME -- dnf install -y php-fpm php-mysqlnd php-mbstring php-xml php-opcache php-pear php-json
lxc exec $NODE_NAME -- mkdir /tmp/restore
lxc file push /work/blog_encrypt_key $NODE_NAME/tmp/restore/;
for f in $(ls); do lxc file push $f $NODE_NAME/tmp/restore/; done
lxc exec $NODE_NAME -- sh -c "for f in $(ls /tmp/restore/*.opensslAES256); do echo $f; done"
lxc exec $NODE_NAME -- sh -c "cd /tmp/restore/;
for f in \$(ls /tmp/restore/*.opensslAES256); do
  echo decripting and uncompressing \$f
  openssl enc -d -aes-256-cbc -pass file:/tmp/restore/blog_encrypt_key -in \$f -out \${f:0:-14} &&
  tar -zxf \${f:0:-14}
done
#restore mysql
echo restoring MySQL
mysql -u root -psekret < /tmp/restore/databases.sql
systemctl restart mysql || echo Error starting MySQL
cp -R /tmp/restore/etc/letsencrypt /etc/
cp -R /tmp/restore/etc/nginx/conf.d/* /etc/nginx/conf.d/
cp -R /tmp/restore/hosts /
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

sed -i '/server {/,/Settings for a TLS enabled server/d' /etc/nginx/nginx.conf
echo '}' >> /etc/nginx/nginx.conf

#sed -i 's/45.56.112.247/${MY_IP}/g' /etc/nginx/conf.d/en-blog.conf
#sed -i 's/45.56.118.251/${MY_IP}/g' /etc/nginx/conf.d/pt-blog.conf
#sed -i 's/127.0.0.1:9000/\/var\/run\/php-fpm\/php-fpm.sock /g' /etc/php-fpm.d/www.conf
systemctl restart php-fpm || echo Error starting php
systemctl restart nginx || echo Error starting nginx
"

echo "${MY_IP} blog.marceloaltmann.com pt.blog.marceloaltmann.com #blog_restore" | sudo tee -a /etc/hosts
cd ${CURRENT_FOLDER}
./test.sh

exit 0

