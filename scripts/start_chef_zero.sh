#!/bin/bash

DIR=`dirname $0`
source $DIR/../common/common.sh

RUNDIR=$DIR/../.run
mkdir -p $RUNDIR

LOGDIR=$DIR/../.logs
mkdir -p $LOGDIR

CHEFDIR=$DIR/../.chef
mkdir -p $CHEFDIR
rm -f $CHEFDIR/knife.rb && ln -s ../$DIR/chef_support_files/chef-zero_knife.rb $CHEFDIR/knife.rb
rm -f $CHEFDIR/chef-zero_node.pem && ln -s ../$DIR/chef_support_files/chef-zero_node.pem $CHEFDIR/chef-zero_node.pem
rm -f $CHEFDIR/chef-zero_validator.pem && ln -s ../$DIR/chef_support_files/chef-zero_validator.pem $CHEFDIR/chef-zero_validator.pem

[ -e $RUNDIR/chef-zero.pid ] && kill -9 $(cat $RUNDIR/chef-zero.pid) > /dev/null 2>&1 && rm $RUNDIR/chef-zero.pid

nohup ruby $DIR/chef_support_files/chef_zero.rb > $LOGDIR/chef-zero.log 2>&1 &
echo $! > $RUNDIR/chef-zero.pid

echo "Chef-Zero is running in the background. Use 'stop_zero.sh' to stop it."
