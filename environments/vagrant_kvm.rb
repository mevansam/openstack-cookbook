env_name = File.basename( __FILE__, ".rb")

name env_name
description "HA OpenStack Environment."

env = YAML.load_file(File.expand_path("../../etc/#{env_name}.yml", __FILE__))

## Pre-process environment variables

openstack_proxy = env['openstack']['endpoints']['openstack_haproxy_name']
openstack_network = env['openstack']['network']

## Build the Chef environment

override_attributes(
    'ntp' => env['ntp'],
    'env' => {
        'http_proxy' => env['http_proxy'],
        'https_proxy' => env['https_proxy'],
        'domain' => env['domain'],

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

        # Highly-Available Proxy load balancer
        # endpoint for all OpenStack services
        'openstack_ha_proxy' => openstack_proxy,

        'region' => env['openstack']['region'],
        'apt' => {
            'live_updates_enabled' => false
        },
        'endpoints' => {
            'host' => openstack_proxy,
            'bind-host' => '0.0.0.0',
            'db' => {
                'host' => env['openstack']['endpoints']['database_server'] || openstack_proxy,
                'port' => env['database']['port']
            },
            'mq' => {
                'host' => env['openstack']['endpoints']['messaging_server'] || openstack_proxy,
                'port' => env['messaging']['ampq_port']
            },
            'identity-api' => {
                'scheme' => 'https',
                'insecure' => true
            },
            'identity-admin' => {
                'scheme' => 'https',
                'insecure' => true
            },
            'image-api' => {
                'scheme' => 'https',
                'insecure' => true
            },
            'block-storage-api' => {
                'scheme' => 'https',
                'insecure' => true
            },
            'compute-api' => {
                'scheme' => 'https',
                'insecure' => true
            },
            'compute-ec2-api' => {
                'scheme' => 'https',
                'insecure' => true
            },
            'compute-ec2-admin' => {
                'scheme' => 'https',
                'insecure' => true
            },
            'compute-novnc' => {
                'scheme' => 'https',
                'insecure' => true
            },
            'network-api' => {
                'scheme' => 'https',
                'insecure' => true
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
        'identity' => {
            'registration' => {
                'insecure' => true
            }
        },
        'network' => {
            'ml2' => {
                'type_drivers' =>
                    openstack_network['ml2']['type_drivers'],
                'tenant_network_types' =>
                    openstack_network['ml2']['tenant_network_types'],
                'tenant_network_tunnel_types' =>
                    openstack_network['ml2']['tunnel_types'],
                'mechanism_drivers' =>
                    openstack_network['ml2']['mechanism_drivers'],
                'flat_networks' => '*',
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
            }
        },
        'dashboard' => {
            'certificate_databag_item' => openstack_proxy,
            'ssl_no_verify' => true
        }
    },
    'haproxy' => {
        'certificate_databag_items' => {
            'default' => openstack_proxy
        },
        'virtual_ip_address' => env['proxy']['vip_address'],
        'virtual_ip_cidr_netmask' => env['proxy']['vip_cidr_netmask'] || 24,
        'virtual_ip_nic' => env['proxy']['vip_nic'],
        'backend_default_ip' => env['proxy']['backend_default_ip'],

        # Each pool name should match a corresponding OpenStack
        # endpoint service as defined in the openstack-common. The
        # os-ha-proxy cookbook looks up the corresponding service
        # ports from the openstack configuration unless it is
        # explicitly specified as for the horizon pools.
        'server_pools' => {
            'db' => {
                'profile' => 'mysql',
                'cluster_role' => 'os-ha-database'
            },
            'mq' => {
                'profile' => 'rabbitmq',
                'cluster_role' => 'os-ha-messaging'
            },
            'mq_admin' => {
                'port' => 15671,
                'profile' => 'ssl',
                'cluster_role' => 'os-ha-messaging'
            },
            'identity-api' => {
                'profile' => 'http',
                'bind_ssl' => 'default',
                'cluster_role' => 'os-ha-identity'
            },
            'identity-admin' => {
                'profile' => 'http',
                'bind_ssl' => 'default',
                'cluster_role' => 'os-ha-identity'
            },
            'image-api' => {
                'profile' => 'http',
                'bind_ssl' => 'default',
                'cluster_role' => 'os-ha-image'
            },
            'block-storage-api' => {
                'profile' => 'http',
                'bind_ssl' => 'default',
                'cluster_role' => 'os-ha-block-storage-kvm-lvm'
            },
            'compute-api' => {
                'profile' => 'http',
                'bind_ssl' => 'default',
                'cluster_role' => 'os-ha-controller-kvm'
            },
            'compute-ec2-api' => {
                'profile' => 'http',
                'bind_ssl' => 'default',
                'cluster_role' => 'os-ha-controller-kvm'
            },
            'compute-novnc' => {
                'profile' => 'http',
                'bind_ssl' => 'default',
                'cluster_role' => 'os-ha-controller-kvm'
            },
            'network-api' => {
                'profile' => 'http',
                'bind_ssl' => 'default',
                'cluster_role' => 'os-ha-controller-kvm'
            },
            'horizon_web' => {
                'port' => 80,
                'profile' => 'http',
                'cluster_role' => 'os-ha-controller-kvm'
            },
            'horizon_web_ssl' => {
                'port' => 443,
                'profile' => 'ssl',
                'cluster_role' => 'os-ha-controller-kvm'
            }
        }
    }
)
