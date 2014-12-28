#!/bin/bash

DIR=`dirname $0`
source $DIR/../common/common.sh

if [ -z "$1" ]; then
	echo "Usage:   ./create_mysql_osdb.sh [environment]"
	echo "Example: ./create_mysql_osdb.sh vagrant_kvm"
	exit 1
fi

CONFIG_FILE=$DIR/../etc/$1.yml
if [ ! -e "$CONFIG_FILE" ]; then
  echo "ERROR: Environment file '$CONFIG_FILE' cannot be found."
  exit 1
fi

env_vals=$(parse_yaml $CONFIG_FILE)
eval $(echo "$env_vals")

db_password=$openstack_passwords_database_password

mysql=`which mysql`
if [ -z "$mysql" ]; then
	mysql="/usr/local/mysql/bin/mysql"
fi
if [ ! -e $mysql ]; then
	echo "Unable to find mysql client: '$mysql'"
	exit 1
fi

for db_user in "keystone" "glance" "cinder" "nova" "neutron" "ceilometer" "heat" "trove" "horizon"; do

	echo "Creating: database and user '$db_user'..."

	sudo $mysql -e " \
		GRANT USAGE ON *.* TO '$db_user'@'localhost'; \
		DROP USER '$db_user'@'localhost'; \
		DROP DATABASE IF EXISTS $db_user;"

	sudo $mysql -e " \
		CREATE DATABASE $db_user; \
		GRANT ALL PRIVILEGES ON $db_user.* TO '$db_user'@'localhost' IDENTIFIED BY '$db_password'; \
		GRANT ALL PRIVILEGES ON $db_user.* TO '$db_user'@'%' IDENTIFIED BY '$db_password';"
done
