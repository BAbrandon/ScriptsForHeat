#!/bin/bash

su -

apt-get update
apt-get install -y git python-pip vim
apt-get upgrade -y python
echo 127.0.0.1 localhost $HOSTNAME >> /etc/hosts

chown cc:cc /home/cc 
cd /home/cc



git clone https://github.com/openstack-dev/devstack.git -b stable/liberty

cd devstack

git clone https://github.com/BAbrandon/ScriptsForHeat.git

cp /ScriptsForHeat/local.conf .

echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
echo net.ipv4.conf.default.rp_filter=0 >> /etc/sysctl.conf
echo net.ipv4.conf.all.rp_filter=0 >> /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

./devstack/stack.sh

runcmd:
  - su -l cc ./start.sh

