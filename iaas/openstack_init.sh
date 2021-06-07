#!/bin/bash

# Set Europe/Rome timezone
sudo timedatectl set-timezone Europe/Rome

# Add routing to the PAAS machine
sudo ip route add 172.17.0.0/24 via 10.235.1.109
sudo ip route add 172.18.0.0/24 via 10.235.1.109

# Create ssh keys for eval
ssh-keygen -f ~/.ssh/ssh_eval -t ecdsa -b 521 -N "" -q
ssh-keygen -f ~/.ssh/ssh_admin -t ecdsa -b 521 -N "" -q

# Move keys
sudo mv ~/.ssh/ssh_eval /home/eval/.ssh/id_rsa
sudo chmod 600 /home/eval/.ssh/id_rsa
sudo chown eval:eval /home/eval/.ssh/id_rsa

PUB_EVAL=`cat ~/.ssh/ssh_eval.pub`
PUB_ADMIN=`cat ~/.ssh/ssh_admin.pub`

sed -i "s|__ECHO_EVAL__|echo '$PUB_EVAL' >> /home/ubuntu/\.ssh/authorized_keys|" ./init_instance.sh
sed -i "s|__ECHO_ADMIN__|echo '$PUB_ADMIN' >> /home/ubuntu/\.ssh/authorized_keys|" ./init_instance.sh

source /home/stack/devstack/accrc/admin/admin
openstack project create progetto
openstack user create --password eval eval
openstack role add --project progetto --user admin admin
openstack role add --project progetto --user eval reader

source ./progetto_openrc.sh

openstack network create network1

openstack subnet create --network network1 \
--subnet-range 10.0.0.0/24 \
--dns-nameserver 208.67.222.222 \
--dns-nameserver 208.67.220.220 \
subnet1 

openstack router create router1

openstack router add subnet router1 subnet1
openstack router set --external-gateway public router1 

SEC_GROUP_SSH_ID=$(openstack security group create progetto-ssh-in --format json | jq -r -M '.id')
openstack security group rule create $SEC_GROUP_SSH_ID --project progetto --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0

SEC_GROUP_SQL_ID=$(openstack security group create progetto-mysql-in --format json | jq -r -M '.id')
openstack security group rule create $SEC_GROUP_SQL_ID --project progetto --protocol tcp --dst-port 3306:3306 --remote-ip 0.0.0.0/0


# Create Ubuntu image
wget -P /var/tmp -c \
https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

openstack image create --disk-format qcow2 --container-format bare --public \
--file /var/tmp/focal-server-cloudimg-amd64.img \
ubuntu-focal-20.04 

openstack flavor create --ram 4096 --disk 50 --vcpus 4 db4G

openstack server create \
--flavor db4G \
--image ubuntu-focal-20.04  \
--network network1 \
--user-data init_instance.sh \
database-server

openstack server add security group database-server progetto-ssh-in
openstack server add security group database-server progetto-mysql-in

DB_VOLUME_ID=$(openstack volume create --size 1 db-volume --format json | jq -r -M '.id')


echo "Waiting for instance to be spawned..."
while [ $(openstack server show database-server -f json | jq -r '.["OS-EXT-STS:vm_state"]') != "active" ]
do
        sleep 1
done

echo "Attaching volume"
openstack server add volume database-server $DB_VOLUME_ID --device /dev/vdb


FLOATING_IP=$(openstack floating ip create public --format json | jq -r -M '.name')
openstack server add floating ip database-server "${FLOATING_IP}"
echo "$FLOATING_IP"

echo "export FLOATING_IP=$FLOATING_IP" >> .bashrc

echo "Configuring port forwarding for database access"
sudo iptables -A PREROUTING -t nat -i ens3 -p tcp --dport 33006 -j DNAT --to $FLOATING_IP:3306
sudo iptables -A FORWARD -p tcp -d $FLOATING_IP --dport 3306 -j ACCEPT