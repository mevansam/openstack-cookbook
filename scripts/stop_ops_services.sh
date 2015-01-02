#!/bin/bash

DIR=`dirname $0`
RUNDIR=$DIR/../.run

if [ -e $RUNDIR/rabbitmq-server.pid ]
then
  sudo kill -15 $(cat $RUNDIR/rabbitmq-server.pid)
  rm $RUNDIR/rabbitmq-server.pid
  echo "RabbitMQ stopped."
fi

mysql_pid=$(ps -ef | grep mysql | awk -F'[=]' '/\/usr\/local\/mysql\/bin\/mysqld / { print $7 }')
if [ -e "$mysql_pid" ]
then
  sudo kill -15 $(sudo cat $mysql_pid)
  sudo rm -f $mysql_pid
  echo "MySQL stopped."
fi
