#!/bin/bash

DIR=`dirname $0`
source $DIR/../common/common.sh

RUNDIR=$DIR/../.run
mkdir -p $RUNDIR

LOGDIR=$DIR/../.logs
mkdir -p $LOGDIR

if [ -z "$1" ]; then
  echo "Usage:   ./start_ops_services.sh [environment]"
  echo "Example: ./start_ops_services.sh vagrant_kvm"
  exit 1
fi

CONFIG_FILE=$DIR/../etc/$1.yml
if [ ! -e "$CONFIG_FILE" ]; then
  echo "ERROR: Environment file '$CONFIG_FILE' cannot be found."
  exit 1
fi

env_vals=$(parse_yaml $CONFIG_FILE)
eval $(echo "$env_vals")


#######################
# Start RabbitMQ Server

RABBITMQ_SERVER=`which rabbitmq-server`
if [ ! -e "$RABBITMQ_SERVER" ]; then
  echo "ERROR: RabbitMQ sbin directory must be set in the PATH."
  exit 1
fi

[ -e $RUNDIR/rabbitmq-server.pid ] && sudo kill -15 $(cat $RUNDIR/rabbitmq-server.pid) > /dev/null 2>&1 && rm $RUNDIR/rabbitmq-server.pid

sudo nohup rabbitmq-server > $LOGDIR/rabbitmq.log 2>&1 &
echo $! > $RUNDIR/rabbitmq-server.pid
echo "RabbitMQ started."

# Wait until RabbitMQ has started
while true; do
  sudo rabbitmqctl list_users > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    user_exists=$(sudo rabbitmqctl list_users | awk -v u=$messaging_user '$1==u { print "yes" }')    
    if [ "$user_exists" == "yes" ]; then
      sudo rabbitmqctl delete_user $messaging_user
      [ $? -eq 0 ] && break
    else
      break
    fi
  fi
  sleep 1
done

sudo rabbitmqctl add_user $messaging_user $messaging_password
sudo rabbitmqctl set_user_tags $messaging_user administrator
sudo rabbitmqctl set_permissions $messaging_user \".*\" \".*\" \".*\"

vhost_exists=$(sudo rabbitmqctl list_vhosts | awk -v h=$messaging_services_path '$1==h { print "yes" }')
[ "$vhost_exists" == "yes" ] && sudo rabbitmqctl delete_vhost $messaging_services_path
sudo rabbitmqctl add_vhost $messaging_services_path
sudo rabbitmqctl set_permissions -p $messaging_services_path $messaging_user ".*" ".*" ".*"

vhost_exists=$(sudo rabbitmqctl list_vhosts | awk -v h=$messaging_compute_path '$1==h { print "yes" }')
[ "$vhost_exists" == "yes" ] && sudo rabbitmqctl delete_vhost $messaging_compute_path
sudo rabbitmqctl add_vhost $messaging_compute_path
sudo rabbitmqctl set_permissions -p $messaging_compute_path $messaging_user ".*" ".*" ".*"


#######################
# Start MySQL Server

mysql_pid=$(ps -ef | grep mysql | awk -F'[=]' '/\/usr\/local\/mysql\/bin\/mysqld / { print $7 }')
[ ! -e "$mysql_pid" ] && [ -e "/usr/local/mysql/support-files/mysql.server" ] && \
  sudo /usr/local/mysql/support-files/mysql.server start
