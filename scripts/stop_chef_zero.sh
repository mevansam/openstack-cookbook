#!/bin/bash

DIR=`dirname $0`
RUNDIR=$DIR/../.run

if [ -e $RUNDIR/chef-zero.pid ]
then
  kill -9 $(cat $RUNDIR/chef-zero.pid)
  rm $RUNDIR/chef-zero.pid
  echo "Chef-Zero stopped."
fi
