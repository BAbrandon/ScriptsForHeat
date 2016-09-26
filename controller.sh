#!/bin/bash



sudo apt-get update
sudo apt-get install -y git python-pip vim
sudo apt-get upgrade -y python


sudo touch hosts
sudo sed -e "s/[ 	]*127.0.0.1[ 	]*localhost[ 	]*$/127.0.0.1 localhost $HOSTNAME/" > hosts
sudo cp hosts /etc/hosts

chown cc:cc /home/cc 
cd /home/cc



git clone https://github.com/openstack-dev/devstack.git -b stable/liberty

cd devstack

git clone https://github.com/BAbrandon/ScriptsForHeat.git

cp /ScriptsForHeat/controller.conf local.conf

VAR=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

printf '\nHOST_IP=%s'$VAR'\n' >> local.conf

touch sysctl.conf
sudo sed -e "s/as needed.$/as needed.\n net.ipv4.ip_forward=1\n/" /etc/sysctl.conf >  sysctl.conf

sudo sed -e "s/as needed.$/as needed.\n net.ipv4.conf.default.rp.filter=0\n/" sysctl.conf > sysctl.conf

sudo sed -e "s/as needed.$/as needed.\n net.ipv4.conf.all.rp.filter=0\n/" sysctl.conf > sysctl.conf

sudo cp sysctl.conf /etc/sysctl.conf

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

./devstack/stack.sh

./unstack.sh
./clean.sh

sudo rm -rf /etc/libvirt/qemu/inst*

sudo virsh list | grep inst | awk '{print $1}' | xargs -n1 virsh
destroy
