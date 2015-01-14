env_name = File.basename( __FILE__, ".rb")

name env_name
description "OpenStack Vagrant KVM Environment."

env = YAML.load_file(File.expand_path("../../etc/#{env_name}.yml", __FILE__))

## Pre-process environment variables

openstack_app_services = openstack_ops_services = env['openstack']['endpoints']['openstack_services']

# If openstack proxy is an IP then simply create a self-signed
# cert for the environment as by default all end-points need to
# be secured via SSL
openstack_app_proxy = openstack_ops_proxy = \
	(openstack_app_services=~/\d+\.\d+\.\d+\.\d+/ ? "#{env_name}.#{env['domain']}" : openstack_app_services)
	
unless Dir.exist?(File.dirname(__FILE__) +  '/../.certs/' + openstack_app_proxy)
    chef_server_url = Chef::Config[:chef_server_url]
    `knife stack upload certificates --server=#{openstack_app_proxy} -E #{env_name} -s #{chef_server_url}`
end

openstack_network = env['openstack']['network']
default_packagess = nil

## Load and evaluate the common openstack environment overrides
eval(IO.read(File.expand_path("../../common/environment.rb", __FILE__)))
