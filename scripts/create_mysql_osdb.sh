#!/bin/bash

if [ -z "$1" ]; then
	echo "Usage: ./create_mysql_osdb.sh [password]"
	exit 1
fi
db_password="$1"

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

	$mysql -e " \
		GRANT USAGE ON *.* TO '$db_user'@'localhost'; \
		DROP USER '$db_user'@'localhost'; \
		DROP DATABASE IF EXISTS $db_user;"

	$mysql -e " \
		CREATE DATABASE $db_user; \
		GRANT ALL PRIVILEGES ON $db_user.* TO '$db_user'@'localhost' IDENTIFIED BY '$db_password'; \
		GRANT ALL PRIVILEGES ON $db_user.* TO '$db_user'@'%' IDENTIFIED BY '$db_password';"
done
