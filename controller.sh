#!/bin/bash



sudo apt-get update
sudo apt-get install -y git python-pip vim
sudo apt-get upgrade -y python


touch host
sudo sed -e "s/[ 	]*127.0.0.1[ 	]*localhost[ 	]*$/127.0.0.1 localhost $HOSTNAME/" /etc/hosts > host
sudo cp host /etc/hosts

chown cc:cc /home/cc 
cd /home/cc



git clone https://github.com/openstack-dev/devstack.git -b stable/liberty

cd devstack

#git clone https://github.com/BAbrandon/ScriptsForHeat.git
touch interfaces
cat <<EOF | cat > interfaces
auto eth0
iface eth0 inet static 
	address 192.168.0.133
	netmask 255.255.255.0
	gateway 192.168.0.1
EOF
sudo cp -f interfaces /etc/network/
#made change to interface have to bring down and up 
ifdown
ifup

cat <<EOF | cat > local.conf

[[local|localrc]]
#credential
SERVICE_TOKEN=azertytoken
ADMIN_PASSWORD=secret
MYSQL_PASSWORD=secret
RABBIT_PASSWORD=secret
SERVICE_PASSWORD=secret



#network
FLAT_INTERFACE=eth0
FIXED_RANGE=192.168.1.0/24
NETWORK_GATEWAY=192.168.1.1
FIXED_NETWORK_SIZE=4096
#HOST_IP=

#multi_host
MULTI_HOST=1


# Enable Logging
LOGFILE=/opt/stack/logs/stack.sh.log
VERBOSE=True
LOG_COLOR=True
SCREEN_LOGDIR=/opt/stack/logs

#service
disable_service n-net
enable_service q-svc
enable_service q-agt
enable_service q-dhcp
enable_service q-l3
enable_service q-meta
enable_service neutron
enable_service q-fwaas
enable_service q-vpn
enable_service q-lbaas
Q_PLUGIN=ml2
Q_ML2_TENANT_NETWORK_TYPE=vxlan


EOF

VAR=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

printf '\nHOST_IP=%s'$VAR'\n' >> local.conf



touch interfaces
cat <<EOF | cat > interfaces
auto eth0
iface eth0 inet static 
        netmask 255.255.255.0
        gateway 192.168.0.1
EOF
printf '	address '$VAR'\n' >> interfaces
sudo cp -f interfaces /etc/network/
ifdown
ifup

touch sysctl.conf
sudo sed -e "s/as needed.$/as needed.\n net.ipv4.ip_forward=1\n/" /etc/sysctl.conf >  sysctl.conf

sudo sed -e "s/as needed.$/as needed.\n net.ipv4.conf.default.rp.filter=0\n/" sysctl.conf > sysctl.conf

sudo sed -e "s/as needed.$/as needed.\n net.ipv4.conf.all.rp.filter=0\n/" sysctl.conf > sysctl.conf

sudo cp sysctl.conf /etc/sysctl.conf

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
cat <<EOF | cat > local.sh
for i in `seq 2 10`; do /opt/stack/nova/bin/nova-manage fixed reserve 10.4.128.$i; done
EOF
./stack.sh

#./unstack.sh
#./clean.sh

#sudo rm -rf /etc/libvirt/qemu/inst*

#sudo virsh list | grep inst | awk '{print $1}' | xargs -n1 virsh
#destroy
