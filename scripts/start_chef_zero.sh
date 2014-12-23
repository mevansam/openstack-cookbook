#!/bin/bash

DIR=`dirname $0`

RUNDIR=$DIR/../.run
mkdir -p $RUNDIR

LOGDIR=$DIR/../.logs
mkdir -p $LOGDIR

[ -e $RUNDIR/chef-zero.pid ] && kill -9 $(cat $RUNDIR/chef-zero.pid) && rm $RUNDIR/chef-zero.pid

nohup ruby $DIR/chef_zero.rb > $LOGDIR/chef-zero.log 2>&1 &
echo $! > $RUNDIR/chef-zero.pid

echo "Chef-Zero is running in the background. Use 'stop_zero.sh' to stop it."
