#!/bin/bash

DIR=`dirname $0`

if [ -z "$1" ]; then
  echo "Usage:   ./start_all.sh [environment]"
  echo "Example: ./start_all.sh vagrant_kvm"
  exit 1
fi

$DIR/start_chef_zero.sh 
$DIR/start_log_servers.sh $1
$DIR/start_ops_services.sh $1
$DIR/create_mysql_osdb.sh $1 

knife stack upload repo --environment=$1 --repo_path=$DIR/..
