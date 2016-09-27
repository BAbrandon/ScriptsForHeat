#/bin/bash

cd ~/devstack
sudo ./unstack.sh
sudo ./clean.sh
sudo rm -rf /opt/stack
sudo rm -rf /local/bin/
