env_name = File.basename( __FILE__, ".rb")

name env_name
description "HA OpenStack Environment."

env = YAML.load_file(File.expand_path("../../etc/#{env_name}.yml", __FILE__))

## Pre-process environment variables

openstack_services = env['openstack']['endpoints']['openstack_ha_proxy']

# If openstack proxy is an IP then simply create a self-signed
# cert for the environment as by default all end-points need to
# be secured via SSL
if openstack_services=~/\d+\.\d+\.\d+\.\d+/

    openstack_proxy = "#{env_name}.#{env['domain']}"
    unless Dir.exist?(File.dirname(__FILE__) +  '/../.certs/' + openstack_proxy)
        chef_server_url = Chef::Config[:chef_server_url]
        `knife stack upload certificates --server=#{openstack_proxy} -E #{env_name} -s #{chef_server_url}`
    end
else
    openstack_proxy =  openstack_services
end

openstack_network = env['openstack']['network']

## Load and evaluate the common openstack environment overrides
eval(IO.read(File.expand_path("../../common/environment.rb", __FILE__)))
