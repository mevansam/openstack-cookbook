name 'kvm_vbox'
description 'Click2Compute OpenStack KVM environment.'

env = YAML.load_file(File.expand_path('../../etc/kvm_vbox.yml', __FILE__))

## Pre-process environment variables

# Extract only the 2nd level domain name of the openstack_proxy value
openstack_proxy = env['openstack']['endpoints']['proxy']

# Determine IP of metadata server
metadata_ip = env['openstack']['endpoints']['metadata_server'] || openstack_proxy
metadata_ip = `ping -c 1 #{env['openstack']['endpoints']['metadata_server']}`[/64 bytes from (\d+\.\d+\.\d+\.\d+)/, 1] \
    if !(metadata_ip=~/\d+\.\d+\.\d+\.\d+/)

openstack_network = env['openstack']['network']

## Build the Chef environment

override_attributes(
    'ntp' => {
        'servers' => env['ntp']['servers']
    },
    'env' => {
        'http_proxy' => env['http_proxy'],
        'https_proxy' => env['https_proxy'],
        'domain' => env['domain'],

        # HA Proxy load balancer for all OpenStack services
        'openstack_proxy' => openstack_proxy,

        # Disables Ubuntu firewall on all Ubunty hosts
        'firewall' => false
    },
    'percona' => {
        'server' => {
            'port' => env['database']['port'],
            'replication' => {
                'port' => env['database']['port']
            }
        },
        'mysql' => {
            # Certificate data bag item containing mysql certs
            'certificate_databag_item' => openstack_proxy
        },
    },
    'rabbitmq' => {
        # Certificate data bag item containing rabbitmq certs
        'certificate_databag_item' => openstack_proxy,
        'ssl_port' => env['messaging']['ampq_port'],
        'web_console_ssl_port' => env['messaging']['ampq_mgmt_port'],
        'virtualhosts' => [
            env['messaging']['services_path'],
            env['messaging']['compute_path'],
        ],
        'policies' => {
            'ha-all' => {
                'pattern' => '.*',
                'params' => { 'ha-mode' => 'all' },
                'vhost' => '/'
            },
            "ha-services-all" => {
                'pattern' => '.*',
                'params' => { 'ha-mode' => 'all' },
                'vhost' => env['messaging']['services_path']
            },
            'ha-compute-all' => {
                'pattern' => '.*',
                'params' => { 'ha-mode' => 'all' },
                'vhost' => env['messaging']['compute_path']
            }
        }
    },
    'openstack' => {
        'region' => env['openstack']['region'],
        'apt' => {
            'live_updates_enabled' => false
        },
        'endpoints' => {
            'host' => env['openstack']['endpoints']['identity_service'] || openstack_proxy,
            'bind-host' => '0.0.0.0',
            'db' => {
                'host' => env['openstack']['endpoints']['database_server'] || openstack_proxy,
                'port' => env['database']['port']
            },
            'mq' => {
                'host' => env['openstack']['endpoints']['messaging_server'] || openstack_proxy,
                'port' => env['messaging']['ampq_port']
            },
            'image-api' => {
                'host' => env['openstack']['endpoints']['image_api_server'] || openstack_proxy,
            },
            'block-storage-api' => {
                'host' => env['openstack']['endpoints']['block_storage_api_server'] || openstack_proxy,
            },
            'compute-api' => {
                'host' => env['openstack']['endpoints']['compute_api_server'] || openstack_proxy,
            },
            'network-api' => {
                'host' => env['openstack']['endpoints']['network_api_server'] || openstack_proxy,
            }
        },
        'mq' => {
            'user' => env['messaging']['user'],
            'orchestration' => {
                'rabbit' => {
                    'vhost' => env['messaging']['services_path'],
                    'use_ssl' => true
                }
            },
            'telemetry' => {
                'rabbit' => {
                    'vhost' => env['messaging']['services_path'],
                    'use_ssl' => true
                }
            },
            'image' => {
                'rabbit' => {
                    'vhost' => env['messaging']['services_path'],
                    'use_ssl' => true
                }
            },
            'block-storage' => {
                'rabbit' => {
                    'vhost' => env['messaging']['compute_path'],
                    'use_ssl' => true
                }
            },
            'compute' => {
                'rabbit' => {
                    'vhost' => env['messaging']['compute_path'],
                    'use_ssl' => true
                }
            },
            'network' => {
                'rabbit' => {
                    'vhost' => env['messaging']['compute_path'],
                    'use_ssl' => true
                }
            }
        },
        'network' => {
            'ml2' => {
                'type_drivers' =>
                    openstack_network['ml2']['type_drivers'],
                'tenant_network_types' =>
                    openstack_network['ml2']['type_drivers'],
                'tenant_network_tunnel_types' =>
                    openstack_network['ml2']['tunnel_types'],
                'mechanism_drivers' => openstack_network['ml2']['mechanism_drivers'],
                'network_vlan_ranges' =>
                    "#{openstack_network['ovs']['physical_network_tag']}:#{openstack_network['ovs']['vlan_ranges']}",
                'vni_ranges' =>
                    openstack_network['ovs']['vni_ranges'],
                'vxlan_group' =>
                    openstack_network['ovs']['vxlan_group'],
                'tunnel_id_ranges' =>
                    openstack_network['ovs']['tunnel_id_ranges']
            },
            'openvswitch' => {
                'tunnel_type' =>
                    openstack_network['ml2']['tunnel_types'],
                'physical_network_tag' =>
                    openstack_network['ovs']['physical_network_tag'],
                'bridge_mappings' =>
                    "#{openstack_network['ovs']['physical_network_tag']}:#{openstack_network['ovs']['external_bridge']}",
                'bridge_mapping_interface' => [
                    "#{openstack_network['ovs']['external_bridge']}:#{openstack_network['ovs']['external_interface']}"
                ]
            },
            'metadata' => {
                'nova_metadata_ip' => metadata_ip
            }
        },
        'dashboard' => {
            'certificate_databag_item' => openstack_proxy
        }
    }
)
