#!/bin/bash

DIR=`dirname $0`
source $DIR/../common/common.sh

RUNDIR=$DIR/../.run
mkdir -p $RUNDIR

if [ -z "$1" ]; then
  echo "Usage:   ./condif_vmnet_nat.sh [environment]"
  echo "Example: ./condif_vmnet_nat.sh vagrant_kvm"
  exit 1
fi

CONFIG_FILE=$DIR/../etc/$1.yml
if [ ! -e "$CONFIG_FILE" ]; then
  echo "ERROR: Environment file '$CONFIG_FILE' cannot be found."
  exit 1
fi

env_vals=$(parse_yaml $CONFIG_FILE)
eval $(echo "$env_vals")

extsubnet=$(sudo route -n get 8.8.8.8 | awk '/gateway/ { print substr($2,0,length($2)-2) }')
extitf=$(ifconfig -a | grep -B 3 $extsubnet | awk '/mtu/ { print substr($1,0,length($1)-1) }')
vmnetitf=$(ifconfig -a | grep -B 3 ${vagrant_data_network%%.0} | awk '/mtu/ { print substr($1,0,length($1)-1) }')

sudo sysctl -w net.inet.ip.forwarding=1

sed 's/\(nat-anchor .*\)/\1\
nat on '"$extitf"' from '"$vmnetitf:network"' -> ('"$extitf"')/' /etc/pf.conf > $RUNDIR/pf.conf

sudo pfctl -f $RUNDIR/pf.conf
sudo pfctl -e
