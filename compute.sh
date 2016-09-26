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
FLOATING_RANGE=10.241.254.0/24
FIXED_RANGE=192.168.1.0/24
NETWORK_GATEWAY=192.168.1.1
FIXED_NETWORK_SIZE=256
PUBLIC_NETWORK_GATEWAY=10.241.254.253
#HOST_IP=

#multi_host
MULTI_HOST=1
SERVICE_HOST=10.241.1.81
DATABASE_TYPE=mysql
MYSQL_HOST=$SERVICE_HOST
RABBIT_HOST=$SERVICE_HOST
GLANCE_HOSTPORT=$SERVICE_HOST:9292
Q_HOST=$SERVICE_HOST
KEYSTONE_AUTH_HOST=$SERVICE_HOST
KEYSTONE_SERVICE_HOST=$SERVICE_HOST
CINDER_SERVICE_HOST=$SERVICE_HOST
NOVA_VNC_ENABLED=True
NOVNCPROXY_URL="http://$SERVICE_HOST:6080/vnc_auto.html"
VNCSERVER_LISTEN=$HOST_IP
VNCSERVER_PROXYCLIENT_ADDRESS=$VNCSERVER_LISTEN

#service
ENABLED_SERVICES=n-cpu,n-api,n-api-meta,neutron,q-agt,q-meta
Q_PLUGIN=ml2
Q_ML2_TENANT_NETWORK_TYPE=vxlan

# Enable Logging
LOGFILE=/opt/stack/logs/stack.sh.log
VERBOSE=True
LOG_COLOR=True
SCREEN_LOGDIR=/opt/stack/logs


EOF

VAR=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')

printf '\nHOST_IP=%s'$VAR'\n' >> local.conf

touch sysctl.conf
sudo sed -e "s/as needed.$/as needed.\n net.ipv4.ip_forward=1\n/" /etc/sysctl.conf >  sysctl.conf

sudo sed -e "s/as needed.$/as needed.\n net.ipv4.conf.default.rp.filter=0\n/" sysctl.conf > sysctl.conf

sudo sed -e "s/as needed.$/as needed.\n net.ipv4.conf.all.rp.filter=0\n/" sysctl.conf > sysctl.conf

sudo cp sysctl.conf /etc/sysctl.conf

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

 ./stack.sh

#sudo ./unstack.sh
#sudo ./clean.sh

#sudo rm -rf /etc/libvirt/qemu/inst*

#sudo virsh list | grep inst | awk '{print $1}' | xargs -n1 virsh destroy
