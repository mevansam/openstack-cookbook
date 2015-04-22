#!/bin/bash

set -x

if [ ! -e "openrc" ]; then
  echo "Unable to find an 'openrc' with the openstack environment."
  exit 1
fi
source openrc

[ -e "trusty-server-cloudimg-amd64-disk1.img" ] || curl -o trusty-server-cloudimg-amd64-disk1.img -L http://uec-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img
glance --insecure image-create --name 'ubuntu-14.04' --disk-format qcow2 --container-format bare --progress --file trusty-server-cloudimg-amd64-disk1.img

[ -e "cirros-0.3.3-x86_64-disk.img" ] || curl -o cirros-0.3.3-x86_64-disk.img -L http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img
glance --insecure image-create --name 'cirros-0.3.3' --disk-format qcow2 --container-format bare --progress --file cirros-0.3.3-x86_64-disk.img

tenant=$(keystone --insecure tenant-list | awk '/admin/ {print $2}')
neutron --insecure net-create --tenant-id $tenant public01 \
  --provider:network_type flat \
  --provider:physical_network physnet \
  --router:external=True --shared
neutron --insecure subnet-create --tenant-id $tenant \
  --name public01-subnet \
  --gateway 10.103.42.1 \
  --dns-nameserver 10.103.42.135 \
  --allocation-pool start=10.103.43.30,end=10.103.43.99 \
  --disable-dhcp \
  public01 10.103.42.0/23

neutron --insecure net-create --tenant-id $tenant private01 \
  --provider:network_type vxlan \
  --provider:segmentation_id 1
neutron --insecure subnet-create --tenant-id $tenant \
  --name private01-subnet \
  --dns-nameserver 10.103.42.135 \
  --enable-dhcp \
  private01 172.16.0.0/22

neutron --insecure router-create public01-router --tenant-id $tenant
neutron --insecure router-gateway-set public01-router public01
neutron --insecure router-interface-add public01-router private01-subnet

secgroupid=$(neutron --insecure security-group-create --tenant-id $tenant \
    --description "all ports open" "all-ports" | awk '$2=="id" { print $4 }')

neutron --insecure security-group-rule-create --tenant-id $tenant \
  --direction ingress \
  --protocol icmp \
  $secgroupid
neutron --insecure security-group-rule-create --tenant-id $tenant \
  --direction ingress \
  --protocol tcp \
  --port-range-min 1 \
  --port-range-max 65335 \
  $secgroupid
neutron --insecure security-group-rule-create --tenant-id $tenant \
  --direction ingress \
  --protocol udp \
  --port-range-min 1 \
  --port-range-max 65335 \
  $secgroupid

[ -e "$HOME/.ssh/id_rsa" ] || (ssh-keygen -N "" -f $HOME/.ssh/id_rsa; chmod 0400 $HOME/.ssh/id_rsa)
[ -e "$HOME/.ssh/id_rsa.pub" ] || ssh-keygen -y -f $HOME/.ssh/id_rsa > $HOME/.ssh/id_rsa.pub
nova --insecure keypair-add --pub-key ~/.ssh/id_rsa.pub $(whoami)

set +x
