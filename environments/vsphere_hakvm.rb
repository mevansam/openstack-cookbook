env_name = File.basename( __FILE__, ".rb")

name env_name
description "OpenStack Vagrant HA KVM Environment."

env = YAML.load_file(File.expand_path("../../etc/#{env_name}.yml", __FILE__))

## Pre-process environment variables

openstack_app_services = openstack_app_proxy = env['openstack']['endpoints']['openstack_app_proxy']
openstack_ops_services = openstack_ops_proxy = env['openstack']['endpoints']['openstack_ops_proxy']

# Create a self-signed cert for ssl end-points
openstack_app_proxy = (openstack_app_proxy=~/\d+\.\d+\.\d+\.\d+/ ? "#{env_name}.#{env['domain']}" : openstack_app_proxy)
unless Dir.exist?(File.dirname(__FILE__) +  '/../.certs/' + openstack_app_proxy)
    chef_server_url = Chef::Config[:chef_server_url]
    `knife stack upload certificates --server=#{openstack_app_proxy} -E #{env_name} -s #{chef_server_url}`
end

openstack_ops_proxy = (openstack_ops_proxy=~/\d+\.\d+\.\d+\.\d+/ ? "#{env_name}.#{env['domain']}" : openstack_ops_proxy)
unless Dir.exist?(File.dirname(__FILE__) +  '/../.certs/' + openstack_ops_proxy)
    chef_server_url = Chef::Config[:chef_server_url]
    `knife stack upload certificates --server=#{openstack_ops_proxy} -E #{env_name} -s #{chef_server_url}`
end

openstack_network = env['openstack']['network']
default_packagess = nil

## Load and evaluate the common openstack environment overrides
eval(IO.read(File.expand_path("../../common/environment.rb", __FILE__)))
