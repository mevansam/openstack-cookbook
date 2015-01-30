# OpenStack environment template

begin

default_attributes(
    'ntp' => env['ntp'],
    'env' => {
        'http_proxy' => env['http_proxy'],
        'https_proxy' => env['https_proxy'],
        'domain' => env['domain'],

        # Disables Ubuntu firewall on all Ubunty hosts
        'firewall' => env['disable_local_firewall'] ? false : nil,

        'packages' => default_packagess
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
            'certificate_databag_item' => openstack_ops_proxy
        },
    },
    'rabbitmq' => {
        # Certificate data bag item containing rabbitmq certs
        'certificate_databag_item' => openstack_ops_proxy,
        'ssl' => env['messaging']['use_ssl'],
        'ssl_port' => env['messaging']['use_ssl'] ? env['messaging']['ampq_port'] : nil, 
        'web_console_ssl' => env['messaging']['use_ssl'],
        'web_console_ssl_port' => env['messaging']['use_ssl'] ? env['messaging']['ampq_mgmt_port'] : nil,
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
        'openstack_app_proxy' => openstack_app_services,
        'openstack_ops_proxy' => openstack_ops_services,

        'logging' => {
            # Work around for bug https://bugs.launchpad.net/openstack-chef/+bug/1365677
            'ignore' => {
                'null' => 'NOTSET',
            },
            'loggers' => env['logs']['loggers']
        },
        'region' => env['openstack']['region'],
        'apt' => {
            'live_updates_enabled' => false
        },
        'endpoints' => {
            'host' => openstack_app_services,
            'bind-host' => '0.0.0.0',
            'db' => {
                'port' => env['database']['port']
            },
            'mq' => {
                'port' => env['messaging']['ampq_port']
            },
            'rsyslog' => {
                'protocol' => 'tcp'
            },
            'identity-api' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['identity-api']['port']
            },
            'identity-admin' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['identity-admin']['port']
            },
            'image-api' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['image-api']['port']
            },
            'block-storage-api' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['block-storage-api']['port']
            },
            'compute-api' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['compute-api']['port']
            },
            'compute-ec2-api' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['compute-ec2-api']['port']
            },
            'compute-ec2-admin' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['compute-ec2-api']['port']
            },
            'compute-novnc' => {
                'port' => env['openstack']['endpoints']['compute-novnc']['port']
            },
            'network-api' => {
                'scheme' => env['openstack']['endpoints']['use_ssl'] ? 'https' : 'http',
                'insecure' => env['openstack']['endpoints']['is_insecure'],
                'port' => env['openstack']['endpoints']['network-api']['port']
            }
        },
        'mq' => {
            'user' => env['messaging']['user'],
            'orchestration' => {
                'rabbit' => {
                    'vhost' => env['messaging']['services_path'],
                    'use_ssl' => env['messaging']['use_ssl']
                }
            },
            'telemetry' => {
                'rabbit' => {
                    'vhost' => env['messaging']['services_path'],
                    'use_ssl' => env['messaging']['use_ssl']
                }
            },
            'image' => {
                'rabbit' => {
                    'vhost' => env['messaging']['services_path'],
                    'use_ssl' => env['messaging']['use_ssl']
                }
            },
            'block-storage' => {
                'rabbit' => {
                    'vhost' => env['messaging']['compute_path'],
                    'use_ssl' => env['messaging']['use_ssl']
                }
            },
            'compute' => {
                'rabbit' => {
                    'vhost' => env['messaging']['compute_path'],
                    'use_ssl' => env['messaging']['use_ssl']
                }
            },
            'network' => {
                'rabbit' => {
                    'vhost' => env['messaging']['compute_path'],
                    'use_ssl' => env['messaging']['use_ssl']
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
            'certificate_databag_item' => openstack_app_proxy,
            'ssl_no_verify' => true
        }
    },
    'haproxy' => {
        'certificate_databag_items' => {
            'app_proxy' => openstack_app_proxy,
            'ops_proxy' => openstack_ops_proxy
        }
    }
)

rescue Exception => msg

    puts "Error: #{msg}"
    puts msg.backtrace.join("\n\t")
end
