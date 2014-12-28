#!/bin/bash

DIR=`dirname $0`
RUNDIR=$DIR/../.run
CHEFDIR=$DIR/../.chef

if [ -e $RUNDIR/chef-zero.pid ]
then
  kill -9 $(cat $RUNDIR/chef-zero.pid)
  rm $RUNDIR/chef-zero.pid
  rm -fr $CHEFDIR
  echo "Chef-Zero stopped."
fi
