#!/bin/bash

DIR=`dirname $0`
RUNDIR=$DIR/../.run

if [ -e $RUNDIR/log.io-server.pid ]
then
  sudo kill -9 $(cat $RUNDIR/log.io-server.pid)
  sudo rm $RUNDIR/log.io-server.pid
  echo "LogIO stopped."
fi

if [ -e $RUNDIR/logstash.pid ]
then
  ps -ef | awk '$3=='$(cat $RUNDIR/logstash.pid)' { print $2 }' | xargs sudo kill -9
  sudo kill -9 $(cat $RUNDIR/logstash.pid)
  sudo rm $RUNDIR/logstash.pid
  echo "Logstash stopped."
fi
