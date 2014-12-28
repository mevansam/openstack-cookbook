#!/bin/bash

DIR=`dirname $0`
source $DIR/../common/common.sh

RUNDIR=$DIR/../.run
mkdir -p $RUNDIR

LOGDIR=$DIR/../.logs
mkdir -p $LOGDIR

if [ -z "$1" ]; then
  echo "Usage:   ./start_log_services.sh [environment]"
  echo "Example: ./start_log_services.sh vagrant_kvm"
  exit 1
fi

CONFIG_FILE=$DIR/../etc/$1.yml
if [ ! -e "$CONFIG_FILE" ]; then
  echo "ERROR: Environment file '$CONFIG_FILE' cannot be found."
  exit 1
fi

env_vals=$(parse_yaml $CONFIG_FILE)
eval $(echo "$env_vals")


#############################
# Create log io configuration

cat << ---END > $HOME/.log.io/log_server.conf
exports.config = {
	host: '0.0.0.0',
	port: $logs_logio_ports_stream
}
---END

cat << ---END > $HOME/.log.io/web_server.conf
exports.config = {
	host: '0.0.0.0',
	port: $logs_logio_ports_http
}
---END

# Start server

if [ -e $RUNDIR/log.io-server.pid ]
then
  sudo kill -9 $(cat $RUNDIR/log.io-server.pid) > /dev/null 2>&1 
  sudo rm $RUNDIR/log.io-server.pid
fi

nohup log.io-server > $LOGDIR/log.io-server.log 2>&1 &
echo $! > $RUNDIR/log.io-server.pid
echo "LogIO started."


#############################################################################################
# Create logstash syslog listeners config with appropriate filters to output to log io stream

LOGSTASH=`which logstash`
if [ ! -e "$LOGSTASH" ]; then
  echo "ERROR: Logstash bin directory must be set in the PATH."
  exit 1
fi
cp -f $DIR/logging_support_files/extra-grok-patterns $(dirname $LOGSTASH)/../patterns
cp -f $DIR/logging_support_files/logio.rb $(dirname $LOGSTASH)/../lib/logstash/codecs/

cat << ---END > $RUNDIR/logstash-syslog.conf
input {
  tcp {
    port => 514
    type => 'syslog'
  }
  udp {
    port => 514
    type => 'syslog'
  }
---END
for t in $(echo "$env_vals" | awk -F'[=\"]' '/logs_syslog_.*_protocol/ { print substr($1, 13, length($0)-27) }'); do

  cat << ---END >> $RUNDIR/logstash-syslog.conf
  $(eval echo \$logs_syslog_${t}_protocol) {
    port => $(eval echo \$logs_syslog_${t}_port)
    type => "$t"
  }
---END
done
cat << ---END >> $RUNDIR/logstash-syslog.conf
}

filter {
  if [type] == "haproxy" {
    grok {
      match => [
        "message", "%{HAPROXYHTTP}",
        "message", "%{HAPROXYTCP}"
      ]
    }
    mutate {
      convert => [ "time_backend_connect", "integer" ]
      convert => [ "time_duration", "integer" ]
      convert => [ "time_queue", "integer" ]
    }
  } else if [message] =~ /INFO access \[-\]/ {
    grok {
      match => { "message" => "<%{POSINT:syslog_pri}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{TIMESTAMP_ISO8601:log_timestamp} %{POSINT:syslog_pid} %{AUDITLOGLEVEL:log_level} access .* %{HOSTNAME:http_client_host} .* \[%{HTTPDATE:http_timestamp}\] \"%{WORD:http_method} %{HTTP_HOST:http_host}%{URIPATH:http_path}(?:%{URIPARAM:http_params})? %{HTTP_VER:http_ver}\" %{POSINT:http_response_code} %{POSINT:http_response_size}" }
      add_tag => http_access
    }
  } else {
    grok {
      match => { "message" => "<%{POSINT:syslog_pri}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}((:\[%{POSINT:syslog_pid}\])?:?)? %{GREEDYDATA:syslog_message}" }
    }
  }
  syslog_pri {
  }
  date {
    match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
  }
  mutate {
    tags => [ "http_access" ]
    convert => [ "http_response_size", "integer" ]
  }
}

output {
  if [type] == "syslog" and "_grokparsefailure" in [tags] {
    file { path => "$(pwd)/${LOGDIR}/failed_syslog_events-%{+YYYY-MM-dd}" }
  }
  tcp {
    codec => logio {
      debug_output => "false"
    }
    host => "127.0.0.1"
    port => $logs_logio_ports_stream
  }
}
---END

# Start server

if [ -e $RUNDIR/logstash.pid ]
then
  ps -ef | awk '$3=='$(cat $RUNDIR/logstash.pid)' { print $2 }' | xargs sudo kill -9
  sudo kill -9 $(cat $RUNDIR/logstash.pid) > /dev/null 2>&1
  sudo rm $RUNDIR/logstash.pid
fi

nohup sudo $LOGSTASH --config $RUNDIR/logstash-syslog.conf --log $LOGDIR/logstash.log > $LOGDIR/logstash-startup.log 2>&1 &
echo $! > $RUNDIR/logstash.pid
echo "Logstash started."
